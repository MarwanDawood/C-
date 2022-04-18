// Copyright 2014-2018 The MathWorks Inc.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>
#include <unistd.h>
#include <errno.h>

#include "bcm_host.h"
#include "interface/vcos/vcos.h"
#include "interface/mmal/mmal.h"
#include "interface/mmal/mmal_buffer.h"
#include "interface/mmal/mmal_port.h"
#include "interface/mmal/util/mmal_util.h"
#include "interface/mmal/util/mmal_util_params.h"
#include "interface/mmal/util/mmal_default_components.h"
#include "interface/mmal/util/mmal_connection.h"
#include "RaspiCamControl.h"
#include "RaspiPreview.h"
#include "RaspiCLI.h"
#include "common.h"
#include "picam.h"


// Defines
#define MMAL_CAMERA_PREVIEW_PORT 0
#define MMAL_CAMERA_VIDEO_PORT   1
#define MMAL_CAMERA_CAPTURE_PORT 2
#define NUM_OUTPUT_BUFFERS 3

#define STILL_PREVIEW_WIDTH         320
#define STILL_PREVIEW_HEIGHT        240

#if defined(DISABLE_JPEG_ENCODING)
#define STILLS_FRAME_RATE_NUM       1
#define STILLS_FRAME_RATE_DEN       1
#else
#define STILL_FRAME_RATE_NUM        3
#define STILL_FRAME_RATE_DEN        1
#endif

#define STILL_FRAME_RATE_NUM        3
#define STILL_FRAME_RATE_DEN        1
#define MW_PREVIEW_FRAME_RATE_NUM   0
#define MW_PREVIEW_FRAME_RATE_DEN   1
#define PID_LEN                     8

enum
{
    CAPTURE_MODE_VIDEO  = 1,
    CAPTURE_MODE_STILL  = 2,
};

typedef struct {
    int quality;
    int width;
    int height;
    int framerate;
    int use_still;
    
    MMAL_COMPONENT_T *camera_component;
    MMAL_COMPONENT_T *encoder_component;
    MMAL_CONNECTION_T *encoder_connection;
    
    MMAL_PORT_T *camera_capture_port;
    MMAL_PORT_T *encoder_output;
    
    MMAL_POOL_T *camera_buffer_pool;
    MMAL_POOL_T *encoder_buffer_pool;
    MMAL_QUEUE_T *bufferQueue;
    
    RASPICAM_CAMERA_PARAMETERS *cameraParams;
    
    void (*bufferCallback)(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer);
} mmalcam_context;

// Global data store for camera context
mmalcam_context gMmalCam;


//Checks if raspivid is running
int8_T isRaspividRunning()
{
    int8_T ret = 1;
    FILE *fp;
    char pidOut[PID_LEN];
    int pidVal = -1;
    strcpy(pidOut,"");
    
    fp = popen("pidof /usr/bin/raspivid","r");
    if (fp == NULL){
        //LOG_PRINT(stderr, "Unable to check whether raspivid is running \n");
        return ret;
    }
        
    if (fgets(pidOut,PID_LEN,fp) == NULL){
        /*Empty output. No raspivid found*/
        return 0;
    }
    
    pidVal = atoi(pidOut);
    if (pidVal > 1){
        return ret;
    }
    else{
        return 0;
    }       
}

// Parses a string containing camera control parameters
static void parse_camera_control_params(const char *cameraParamsStr, RASPICAM_CAMERA_PARAMETERS *cameraParams)
{
    char *control_params_tok = alloca(strlen(cameraParamsStr) + 1);
    strcpy(control_params_tok, cameraParamsStr);
    
    char *next_param = strtok(control_params_tok, " ");
    
    while (next_param != NULL) {
        char *param_val = strtok(NULL, " ");
        if (raspicamcontrol_parse_cmdline(cameraParams, next_param + 1, param_val) < 2) {
            next_param = param_val;
        } else {
            next_param = strtok(NULL, " ");
        }
    }
}

static void disablePort(MMAL_PORT_T *port)
{
    if (port && port->is_enabled) {
        mmal_port_disable(port);
    }
}

static void camera_control_callback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
    if (buffer->cmd != MMAL_EVENT_PARAMETER_CHANGED) {
        LOG_PRINT(stderr, "Received unexpected camera control callback event, 0x%08x",
                buffer->cmd);
    }
    mmal_buffer_header_release(buffer);
}

static MMAL_STATUS_T connect_ports(MMAL_PORT_T *output_port, MMAL_PORT_T *input_port, MMAL_CONNECTION_T **connection)
{
    MMAL_STATUS_T status;
    
    status =  mmal_connection_create(connection, output_port, input_port,
            MMAL_CONNECTION_FLAG_TUNNELLING | MMAL_CONNECTION_FLAG_ALLOCATION_ON_INPUT);
    if (status == MMAL_SUCCESS) {
        status =  mmal_connection_enable(*connection);
        if (status != MMAL_SUCCESS) {
            mmal_connection_destroy(*connection);
        }
    }
    
    return status;
}

static void bufferCallback(MMAL_PORT_T *port, MMAL_BUFFER_HEADER_T *buffer)
{
    mmalcam_context *mmalcam = (mmalcam_context *) port->userdata;
    mmal_queue_put(mmalcam->bufferQueue, buffer);
}


static void set_port_format(int width, int height, MMAL_ES_FORMAT_T *format)
{
#if defined(DISABLE_JPEG_ENCODING)
    format->encoding = MMAL_ENCODING_RGB24;
    format->encoding_variant = 0;
    format->es->video.width = width;
    format->es->video.height = height;
    format->es->video.crop.x = 0;
    format->es->video.crop.y = 0;
    format->es->video.crop.width = width;
    format->es->video.crop.height = height;
	format->es->video.frame_rate.num = STILLS_FRAME_RATE_NUM;
    format->es->video.frame_rate.den = STILLS_FRAME_RATE_DEN;
#else
    format->encoding = MMAL_ENCODING_OPAQUE;
    format->encoding_variant = MMAL_ENCODING_I420;
    format->es->video.width = width;
    format->es->video.height = height;
    format->es->video.crop.x = 0;
    format->es->video.crop.y = 0;
    format->es->video.crop.width = width;
    format->es->video.crop.height = height;
#endif 
}


static void set_video_port_format(mmalcam_context *mmalcam, MMAL_ES_FORMAT_T *format)
{
    set_port_format(mmalcam->width, mmalcam->height, format);
    format->es->video.frame_rate.num = mmalcam->framerate;
    format->es->video.frame_rate.den = 1;
}

static MMAL_STATUS_T create_encoder_component(mmalcam_context *mmalcam)
{
    MMAL_COMPONENT_T *encoder = NULL;
    MMAL_PORT_T *encoder_input = NULL;
    MMAL_PORT_T *encoder_output = NULL;
    MMAL_STATUS_T status;
    
    status = mmal_component_create(MMAL_COMPONENT_DEFAULT_IMAGE_ENCODER, &encoder);
    if (status != MMAL_SUCCESS) {
        LOG_PRINT(stderr, "Cannot create encoder: %d\n", 10);
        goto error;
    }
    
    if (!encoder->input_num || !encoder->output_num) {
        LOG_PRINT(stderr, "Cannot create encoder: %d\n", 11);
        goto error;
    }
    
    encoder_input = encoder->input[0];
    encoder_output = encoder->output[0];
    
    // We want same format on input and output
    mmal_format_copy(encoder_output->format, encoder_input->format);
    
    // Set encoder parameters. Note that we set encoding type to JPEG
    encoder_output->format->encoding = MMAL_ENCODING_JPEG;
    encoder_output->buffer_size = encoder_output->buffer_size_recommended;
    if (encoder_output->buffer_size < encoder_output->buffer_size_min) {
        encoder_output->buffer_size = encoder_output->buffer_size_min;
    }
    encoder_output->buffer_num = encoder_output->buffer_num_recommended;
    if (encoder_output->buffer_num < encoder_output->buffer_num_min) {
        encoder_output->buffer_num = encoder_output->buffer_num_min;
    }
    
    // Set frame rate to 0. It will later be updated when input is 
    // connected to output
    encoder_output->format->es->video.frame_rate.num = 0;
    encoder_output->format->es->video.frame_rate.den = 1;
    
    // Commit the port changes to the output port
    status = mmal_port_format_commit(encoder_output);
    if (status != MMAL_SUCCESS) {
        LOG_PRINT(stderr, "Cannot create encoder: %d\n", 12);
        goto error;
    }
    
    // Set the JPEG quality level
    status = mmal_port_parameter_set_uint32(encoder_output, MMAL_PARAMETER_JPEG_Q_FACTOR, mmalcam->quality);
    if (status != MMAL_SUCCESS) {
        LOG_PRINT(stderr, "Cannot create encoder: %d\n", 13);
        goto error;
    }
    
    //  Enable component
    status = mmal_component_enable(encoder);
    if (status != MMAL_SUCCESS) {
        LOG_PRINT(stderr, "Cannot create encoder: %d\n", 14);
        goto error;
    }
    mmalcam->encoder_component = encoder;
    mmalcam->encoder_output = encoder_output;
    mmalcam->bufferCallback = bufferCallback;
    
    return status;
    
    error:
        if (encoder) {
            mmal_component_destroy(encoder);
            mmalcam->encoder_component = NULL;
        }
        
        return status;
}

#if defined(DISABLE_JPEG_ENCODING)
static int create_camera_component(mmalcam_context *mmalcam, int capture_mode,int width, int height)
#else
static int create_camera_component(mmalcam_context *mmalcam, int capture_mode)
#endif
{
    MMAL_STATUS_T status;
    MMAL_COMPONENT_T *camera_component = 0;
    MMAL_PORT_T *capture_port = NULL;
    MMAL_PARAMETER_CAMERA_CONFIG_T cam_config = {
        { MMAL_PARAMETER_CAMERA_CONFIG, sizeof(cam_config) },
        .max_stills_w = mmalcam->width,
        .max_stills_h = mmalcam->height,
        .stills_yuv422 = 0,
        .one_shot_stills = 0,
        .max_preview_video_w = mmalcam->width,
        .max_preview_video_h = mmalcam->height,
        .num_preview_video_frames = 3,
        .stills_capture_circular_buffer_height = 0,
        .fast_preview_resume = 0,
        .use_stc_timestamp = MMAL_PARAM_TIMESTAMP_MODE_RESET_STC };
        
        status = mmal_component_create(MMAL_COMPONENT_DEFAULT_CAMERA, &camera_component);
        if (status != MMAL_SUCCESS) {
            LOG_PRINT(stderr, "Cannot create MMAL camera component %s\n",
                    MMAL_COMPONENT_DEFAULT_CAMERA);
            goto error;
        }
        
        if (camera_component->output_num == 0) {
            LOG_PRINT(stderr, "Camera has no output port %s\n",
                    MMAL_COMPONENT_DEFAULT_CAMERA);
            goto error;
        }
        
        status = mmal_port_enable(camera_component->control, camera_control_callback);
        if (status) {
            LOG_PRINT(stderr, "Cannot enable control port %s\n",
                    MMAL_COMPONENT_DEFAULT_CAMERA);
            goto error;
        }
        
        // Default camera configuration
        switch(capture_mode)
        {
            case CAPTURE_MODE_VIDEO:
            {
                capture_port = camera_component->output[MMAL_CAMERA_VIDEO_PORT];
                mmalcam->bufferCallback = bufferCallback;
                set_video_port_format(mmalcam, capture_port->format);
#if !defined(DISABLE_JPEG_ENCODING)                  
                capture_port->format->encoding = MMAL_ENCODING_I420;
#endif                       
                break;
            }
            
            case CAPTURE_MODE_STILL:
            {
                cam_config.one_shot_stills = 1;
                
                capture_port = camera_component->output[MMAL_CAMERA_CAPTURE_PORT];
                mmalcam->bufferCallback = bufferCallback;
                set_port_format(mmalcam->width, mmalcam->height, capture_port->format);
#if !defined(DISABLE_JPEG_ENCODING)                
                capture_port->format->encoding = MMAL_ENCODING_I420;
                capture_port->format->es->video.frame_rate.num = STILL_FRAME_RATE_NUM;
                capture_port->format->es->video.frame_rate.num = STILL_FRAME_RATE_DEN;
#endif                
                
                MMAL_PORT_T *preview_port = camera_component->output[MMAL_CAMERA_PREVIEW_PORT];
                
#if defined(DISABLE_JPEG_ENCODING)
                set_port_format(width, height, preview_port->format);
#else
                set_port_format(STILL_PREVIEW_WIDTH, STILL_PREVIEW_HEIGHT, preview_port->format);
#endif
                preview_port->format->es->video.frame_rate.num = MW_PREVIEW_FRAME_RATE_NUM;
                preview_port->format->es->video.frame_rate.num = MW_PREVIEW_FRAME_RATE_DEN;
                if (mmal_port_format_commit(preview_port)) {
                    LOG_PRINT(stderr, "Cannot configure preview %s\n",
                            MMAL_COMPONENT_DEFAULT_CAMERA);
                    goto error;
                }
                break;
            }
        }
        mmal_port_parameter_set(camera_component->control, &cam_config.hdr);
        
        // Commit capture parameters
        status = mmal_port_format_commit(capture_port);
        if (status) {
            LOG_PRINT(stderr, "Cannot commit capture parameters %s\n",
                    MMAL_COMPONENT_DEFAULT_CAMERA);
            goto error;
        }
        
        // Ensure there are enough buffers to avoid dropping frames
        if (capture_port->buffer_num < NUM_OUTPUT_BUFFERS) {
            capture_port->buffer_num = NUM_OUTPUT_BUFFERS;
        }
        
        status = mmal_component_enable(camera_component);
        if (status) {
            LOG_PRINT(stderr, "Cannot enable camera %s\n",
                    MMAL_COMPONENT_DEFAULT_CAMERA);
            goto error;
        }
        
        raspicamcontrol_set_all_parameters(camera_component, mmalcam->cameraParams);
        mmalcam->camera_component = camera_component;
        mmalcam->camera_capture_port = capture_port;
        mmalcam->camera_capture_port->userdata = (struct MMAL_PORT_USERDATA_T *) mmalcam;
        return 0;
        
        error:
            if (mmalcam->camera_component != NULL ) {
                mmal_component_destroy(camera_component);
                mmalcam->camera_component = NULL;
            }
            
            return -1;
}

static void destroy_camera_component(mmalcam_context *mmalcam)
{
    if (mmalcam->camera_component) {
        mmal_component_destroy(mmalcam->camera_component);
        mmalcam->camera_component = NULL;
    }
}

static void destroy_encoder_component(mmalcam_context *mmalcam)
{
    if (mmalcam->encoder_component) {
        mmal_component_destroy(mmalcam->encoder_component);
        mmalcam->encoder_component = NULL;
    }
}

#if defined(DISABLE_JPEG_ENCODING)
static int create_camera_buffer_structures(mmalcam_context *mmalcam)
{
    mmalcam->camera_buffer_pool = mmal_pool_create(mmalcam->camera_capture_port->buffer_num,
            mmalcam->camera_capture_port->buffer_size);
    if (mmalcam->camera_buffer_pool == NULL ) {
        LOG_PRINT(stderr, "Cannot create buffer pool for the camera %s\n",
                MMAL_COMPONENT_DEFAULT_CAMERA);
        return -1;
    }
    
    mmalcam->bufferQueue = mmal_queue_create();
    if (mmalcam->bufferQueue == NULL ) {
        LOG_PRINT(stderr, "Cannot create buffer pool for the camera %s\n",
                MMAL_COMPONENT_DEFAULT_CAMERA);
        return -1;
    }
    
    return 0;
}

static void destroy_camera_buffer_structures(mmalcam_context * mmalcam)
{
    if (mmalcam->bufferQueue != NULL ) {
        mmal_queue_destroy(mmalcam->bufferQueue);
        mmalcam->bufferQueue = NULL;
    }
    
    if (mmalcam->camera_buffer_pool != NULL ) {
        mmal_pool_destroy(mmalcam->camera_buffer_pool);
        mmalcam->camera_buffer_pool = NULL;
    }
}
#endif


static int create_encoder_buffer_structures(mmalcam_context *mmalcam)
{
    mmalcam->encoder_buffer_pool = mmal_pool_create(mmalcam->encoder_output->buffer_num,
            mmalcam->encoder_output->buffer_size);
    if (mmalcam->encoder_buffer_pool == NULL ) {
        LOG_PRINT(stderr, "Cannot create encoder pool for the camera %s\n",
                MMAL_COMPONENT_DEFAULT_CAMERA);
        return -1;
    }
    
    mmalcam->bufferQueue = mmal_queue_create();
    if (mmalcam->bufferQueue == NULL ) {
        LOG_PRINT(stderr, "Cannot create encoder pool for the camera %s\n",
                MMAL_COMPONENT_DEFAULT_CAMERA);
        return -1;
    }
    
    return 0;
}

static int send_pooled_buffers_to_port(MMAL_POOL_T *pool, MMAL_PORT_T *port)
{
    int i;
    int num = mmal_queue_length(pool->queue);
    
    for (i = 0; i < num; i++) {
        MMAL_BUFFER_HEADER_T *buffer = mmal_queue_get(pool->queue);
        
        if (!buffer) {
            LOG_PRINT(stderr, "Buffer allocation error %s\n",
                    MMAL_COMPONENT_DEFAULT_CAMERA);
            return -1;
        }
        
        if (mmal_port_send_buffer(port, buffer) != MMAL_SUCCESS) {
            LOG_PRINT(stderr, "Buffer allocation error %s\n",
                    MMAL_COMPONENT_DEFAULT_CAMERA);
            return -1;
        }
    }
    
    return 0;
}

static void destroy_encoder_buffer_structures(mmalcam_context * mmalcam)
{
    if (mmalcam->bufferQueue != NULL ) {
        mmal_queue_destroy(mmalcam->bufferQueue);
        mmalcam->bufferQueue = NULL;
    }
    
    if (mmalcam->encoder_buffer_pool != NULL ) {
        mmal_pool_destroy(mmalcam->encoder_buffer_pool);
        mmalcam->encoder_buffer_pool = NULL;
    }
}

// Initialize camera
int EXT_CAMERABOARD_init(const int width, const int height,
        const int frameRate, const int quality, const char *cameraParamsStr)
{
    // always terminate previous connection before starting a new one
    int result = EXT_CAMERABOARD_terminate();
    
#if defined(DISABLE_JPEG_ENCODING)
	bcm_host_init();
#endif    
    
    mmalcam_context *mmalcam = &gMmalCam;
    int status;
    int capture_mode;
    
    mmalcam->cameraParams = (RASPICAM_CAMERA_PARAMETERS *)malloc(sizeof(RASPICAM_CAMERA_PARAMETERS));
    if (mmalcam->cameraParams == NULL) {
        LOG_PRINT(stdout, "camera params couldn't be allocated: %d", 0);
        return ERR_CAMERABOARD_INIT;
    }
    
    // Set camera parameters
    raspicamcontrol_set_defaults(mmalcam->cameraParams);
    mmalcam->width     = width;
    mmalcam->height    = height;
    mmalcam->framerate = frameRate / 2; // Temporary fix for 15a
    mmalcam->quality   = quality;
    mmalcam->use_still = 0;
    parse_camera_control_params(cameraParamsStr, mmalcam->cameraParams);
    if (mmalcam->use_still) {
        capture_mode = CAPTURE_MODE_STILL;
    }
    else {
        capture_mode = CAPTURE_MODE_VIDEO;
    }
    
    // Create MMAL camera component
#if defined(DISABLE_JPEG_ENCODING)
    status = create_camera_component(mmalcam, capture_mode, width, height);
#else
    status = create_camera_component(mmalcam, capture_mode);
#endif
    if (status != 0) {
        LOG_PRINT(stderr, "MMAL camera capture port enabling failed: %d", 0);
    }
    
    
#if defined(DISABLE_JPEG_ENCODING)
    if (status == 0) {
        status = create_camera_buffer_structures(mmalcam);
        if (status != 0) {
            LOG_PRINT(stderr, "MMAL camera capture port enabling failed: %d", 0);
        }
    }
    
    if (status == 0) {
        status = mmal_port_enable(mmalcam->camera_capture_port, mmalcam->bufferCallback);
        if (status != 0) {
            LOG_PRINT(stderr, "MMAL camera capture port enabling failed: %d", 0);
        }
    }
#else
    if (status == 0) {
        status = create_encoder_component(mmalcam);
        if (status != 0) {
            LOG_PRINT(stderr, "Cannot create encoder: %d", 0);
        }
    }
    if (status == 0) {
        status = create_encoder_buffer_structures(mmalcam);
        if (status != 0) {
            LOG_PRINT(stderr, "MMAL encoder port buffer failed: %d", 0);
        }
    }
    
    if (status == 0) {
        MMAL_PORT_T *camera_video_port   = mmalcam->camera_component->output[MMAL_CAMERA_VIDEO_PORT];
        MMAL_PORT_T *encoder_input  = mmalcam->encoder_component->input[0];
        MMAL_PORT_T *encoder_output = mmalcam->encoder_component->output[0];
        
        status = connect_ports(camera_video_port, encoder_input, &mmalcam->encoder_connection);
        if (status != MMAL_SUCCESS) {
            LOG_PRINT(stderr, "MMAL encoder port buffer failed: %d", 0);
        }
        
        // Enable the encoder output port and tell it its callback function
        encoder_output->userdata = (struct MMAL_PORT_USERDATA_T *) mmalcam;
        status = mmal_port_enable(encoder_output, mmalcam->bufferCallback);
        if (status != MMAL_SUCCESS) {
            LOG_PRINT(stderr, "MMAL encoder port buffer failed: %d", 0);
        }
    }
#endif
    
    if (status == 0) {
        status = mmal_port_parameter_set_boolean(mmalcam->camera_capture_port, MMAL_PARAMETER_CAPTURE, 1);
        if (status != MMAL_SUCCESS) {
            LOG_PRINT(stderr, "MMAL camera capture start failed: %d", 0);
        }
    }
    
#if defined(DISABLE_JPEG_ENCODING)
    if (status == 0) {
        status = send_pooled_buffers_to_port(mmalcam->camera_buffer_pool, mmalcam->camera_capture_port);
        if (status != 0) {
            LOG_PRINT(stderr, "MMAL camera buffer start failed: %d", 0);
        }
    }
#else
    if (status == 0) {
        status = send_pooled_buffers_to_port(mmalcam->encoder_buffer_pool, mmalcam->encoder_output);
        if (status != 0) {
            LOG_PRINT(stderr, "MMAL encoder buffer start failed: %d", 0);
        }
    }
#endif
    
    // Check status. If non-zero clean-up.
    if (status != 0) {
        EXT_CAMERABOARD_terminate();
        status = ERR_CAMERABOARD_INIT;
        return status;
    }
    
    // If we hit this point, camera is initialized successfully
    return 0;
}

// Terminate cameraboard
int EXT_CAMERABOARD_terminate(void)
{
    mmalcam_context *mmalcam = &gMmalCam;
    
    if (mmalcam->camera_component) {
        disablePort(mmalcam->camera_capture_port);
        mmal_component_disable(mmalcam->camera_component);
#if defined(DISABLE_JPEG_ENCODING)
        destroy_camera_buffer_structures(mmalcam);
#endif
        destroy_camera_component(mmalcam);
    }
    
#if !defined(DISABLE_JPEG_ENCODING)
    if (mmalcam->encoder_component) {
        disablePort(mmalcam->encoder_output);
        mmal_component_disable(mmalcam->encoder_component);
        destroy_encoder_buffer_structures(mmalcam);
        destroy_encoder_component(mmalcam);
    }
#endif
    
    if (mmalcam->cameraParams) {
        free(mmalcam->cameraParams);
        mmalcam->cameraParams = NULL;
    }
    
    return 0;
}

// Set camera control parameters
int EXT_CAMERABOARD_control(const char *controlParams)
{
    mmalcam_context *mmalcam = &gMmalCam;
    
    if ((mmalcam->cameraParams) && (mmalcam->camera_component)) {
        parse_camera_control_params(controlParams, mmalcam->cameraParams);
        
        // Make sure horizontal flip and vertical flip parameters are handled
        // correctly
        if (!strstr(controlParams, "-hf")) {
            mmalcam->cameraParams->hflip = 0;
        }
        if (!strstr(controlParams, "-vf")) {
            mmalcam->cameraParams->vflip = 0;
        }
                
        // This call always returns an error. Hence we do not check the
        // return value.
        raspicamcontrol_set_all_parameters(mmalcam->camera_component, mmalcam->cameraParams);
    }
    
    return 0;
}

// Get a frame from the camera
#if !defined(DISABLE_JPEG_ENCODING)
int EXT_CAMERABOARD_snapshot(uint8_T *data, uint32_T *dataSize)
{
    mmalcam_context *mmalcam = &gMmalCam;
    int frameComplete;
    
    frameComplete = 0;
    *dataSize = 0;
    do {
        MMAL_BUFFER_HEADER_T *buffer = mmal_queue_wait(mmalcam->bufferQueue);
        
        if (buffer != NULL) {
            mmal_buffer_header_mem_lock(buffer);
            memcpy(data + (*dataSize), buffer->data, buffer->length);
            *dataSize += buffer->length;
            mmal_buffer_header_mem_unlock(buffer);
            
            // Check if the frame is complete
            if (buffer->flags & (MMAL_BUFFER_HEADER_FLAG_FRAME_END | MMAL_BUFFER_HEADER_FLAG_TRANSMISSION_FAILED)) {
                frameComplete = 1;
            }
            
            // Release buffer back to the pool
            mmal_buffer_header_release(buffer);
        }
        
        // Add a new buffer to the camera pool
        if (mmalcam->encoder_output->is_enabled) {
            MMAL_STATUS_T status = MMAL_SUCCESS;
            MMAL_BUFFER_HEADER_T *new_buffer = mmal_queue_get(mmalcam->encoder_buffer_pool->queue);
            
            if (new_buffer) {
                status = mmal_port_send_buffer(mmalcam->encoder_output, new_buffer);
            }
            
            if (!new_buffer || status != MMAL_SUCCESS) {
                LOG_PRINT(stderr, "Cannot return buffer to camera: %d", 0);
            }
        }
    } while (!frameComplete && mmalcam->encoder_output->is_enabled);
    
    return 0;
}
#else
int EXT_CAMERABOARD_snapshot(uint8_T *data, uint32_T *dataSize)
{
    mmalcam_context *mmalcam = &gMmalCam;
    int frameComplete;
    
    frameComplete = 0;
    *dataSize = 0;
    do {
        MMAL_BUFFER_HEADER_T *buffer = mmal_queue_wait(mmalcam->bufferQueue);
        
        if (buffer != NULL) {
            mmal_buffer_header_mem_lock(buffer);
            memcpy(data + (*dataSize), buffer->data, buffer->length);
            *dataSize += buffer->length;
            mmal_buffer_header_mem_unlock(buffer);
            
            // Check if the frame is complete
            if (buffer->flags & (MMAL_BUFFER_HEADER_FLAG_FRAME_END | MMAL_BUFFER_HEADER_FLAG_TRANSMISSION_FAILED)) {
                frameComplete = 1;
            }
            
            // Release buffer back to the pool
            mmal_buffer_header_release(buffer);
        }
        
        // Add a new buffer to the camera pool
        if (mmalcam->camera_capture_port->is_enabled) {
            MMAL_STATUS_T status = MMAL_SUCCESS;
            MMAL_BUFFER_HEADER_T *new_buffer = mmal_queue_get(mmalcam->camera_buffer_pool->queue);
            
            if (new_buffer) {
                status = mmal_port_send_buffer(mmalcam->camera_capture_port, new_buffer);
            }
            
            if (!new_buffer || status != MMAL_SUCCESS) {
                LOG_PRINT(stderr, "Cannot return buffer to camera: %d", 0);
            }
        }
    } while (!frameComplete && mmalcam->camera_capture_port->is_enabled);
    
    return 0;
}
#endif

// [EOF]