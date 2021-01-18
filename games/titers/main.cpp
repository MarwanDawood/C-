#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>
#include <time.h>
using namespace sf;

#define PXL (18)
#define H (20)
#define W (10)
#define WINDOW_WIDTH (320)
#define WINDOW_HEIGHT (480)

enum
{
    enum_ok,
    enum_gameover,
    enum_line_complete
};

// SMFL elements
RenderWindow window(VideoMode(WINDOW_WIDTH, WINDOW_HEIGHT), "Tetris Game!");
Texture tetris;
Texture background;
Texture gameOver;
Sprite s_tetris(tetris);
Sprite s_background(background);
Sprite s_gameOver(gameOver);
SoundBuffer gameOverBuff;
SoundBuffer gameLineBuff;
Sound gameOverSound;
Sound gameLineSound;

// usable window area
int field[H][W] = {0};
int dx = 0;
bool rotate = false;
bool lost = false;
int colorNum = 1;
float timer = 0;
float delay = 0.3;
Clock clk;

// each element represents a figure
struct Point
{
    int x, y;
} a[4], b[4];

/* Pixels order of the figure
    0 1
    2 3
    4 5
    6 7
*/
int figures[7][4] =
    {
        1, 3, 5, 7, //I
        2, 4, 5, 7, //Z
        3, 5, 4, 6, //S
        3, 5, 4, 7, //T
        2, 3, 5, 7, //L
        3, 5, 7, 6, //J
        2, 3, 4, 5, //O
};

// check if the object has reached the window bottom
static bool is_tetris_out_field(void)
{
    bool ret = true; // nok
    for (int i = 0; i < 4; i++)
    {
        // check if pixel is valid and still did not reach the boundaries
        if ((a[i].x < 0) || (a[i].x >= W) || (a[i].y >= H))
        {
            ret = false; // ok
            break;
        }
        // this pixel is already occupied
        else if (field[a[i].y][a[i].x])
        {
            ret = false; // ok
            break;
        }
    }
    return ret;
}

static void tetris_tick(void)
{
    if (timer > delay)
    {
        for (int i = 0; i < 4; i++)
        {
            b[i] = a[i];
            a[i].y += 1;
        }
        if ((!is_tetris_out_field()) && (false == lost))
        {
            for (int i = 0; i < 4; i++)
                field[b[i].y][b[i].x] = colorNum;
            // random color
            colorNum = 1 + rand() % 7;
            // random figure
            int n = rand() % 7;
            for (int i = 0; i < 4; i++)
            {
                a[i].x = figures[n][i] % 2; // result in 0 and 1
                a[i].y = figures[n][i] / 2; // result in 0, 1, 2 and 3
            }
        }
        timer = 0;
    }
                dx = 0;
            rotate = false;
            delay = 0.3;
}

static int tetris_check_lines(void)
{
    int height = H - 1;
    int ret = enum_ok;

    for (int i = H - 1; i > 0; i--)
    {
        int cntWidth = 0;
        for (int j = 0; j < W; j++)
        {
            if (field[i][j])
            {
                cntWidth++;
                if (field[1][j])
                    ret = enum_gameover;
            }
            field[height][j] = field[i][j];
        }
        // if line is not full, then keep it by assigning the field value to it
        if (cntWidth < W)
            height--;
        // if line is full, then overwrite it with the next line
        else
            ret = enum_line_complete;
    }
    return ret;
}

static void tetris_key(void)
{
    Event ev;
    while (window.pollEvent(ev))
    {
        if (ev.type == Event::Closed)
            window.close();
        if (ev.type == Event::KeyPressed)
        {
            if (ev.key.code == Keyboard::Up)
                rotate = true;
            else if (ev.key.code == Keyboard::Left)
                dx = -1;
            else if (ev.key.code == Keyboard::Right)
                dx = 1;
        }
    }
    if (Keyboard::isKeyPressed(Keyboard::Down))
        delay = 0.05;
}

static void tetris_move()
{
    // x direction
    for (int i = 0; i < 4; i++)
    {
        b[i] = a[i];
        a[i].x += dx;
    }
    if (!is_tetris_out_field())
        for (int i = 0; i < 4; i++)
            a[i] = b[i];
}

static void tetris_rotate(void)
{
    if (rotate)
    {
        // center of rotation (second sprite)
        Point p = a[1];
        for (int i = 0; i < 4; i++)
        {
            /* for figure I
            (1,0)
            (1,1)
            (1,2)
            (1,3)
            -
            (1,1)
            =
            (-1,0) (0,0) (1,0) (2,0)
            
            then

            (1,1)
            -
            (-1,0) (0,0) (1,0) (2,0)
            =
            (2,1) (1,1) (0,1) (-1,1)
        */
            int x = a[i].y - p.y;
            int y = a[i].x - p.x;
            a[i].x = p.x - x;
            a[i].y = p.y - y;
        }
        if (!is_tetris_out_field())
            for (int i = 0; i < 4; i++)
                a[i] = b[i];
    }
}

int main(void)
{
    tetris.loadFromFile("media/tetris.png");
    Sprite s_tetris(tetris);
    background.loadFromFile("media/bg.png");
    Sprite s_background(background);
    s_tetris.setTextureRect(IntRect(0, 0, PXL, PXL));
    gameOver.loadFromFile("media/gameover.jpeg");
    Sprite s_gameOver(gameOver);

    gameOverBuff.loadFromFile("media/gameover.wav");
    gameOverSound.setBuffer(gameOverBuff);
    gameLineBuff.loadFromFile("media/line.wav");
    gameLineSound.setBuffer(gameLineBuff);

    int readCheck = enum_ok;
    bool runOnce = false;

    srand(time(0));

    while (window.isOpen())
    {
        float time = clk.getElapsedTime().asSeconds();
        clk.restart();
        timer += time;

        tetris_key();
        tetris_move();
        // executes after sprite initialization and drawing
        tetris_rotate();
        tetris_tick();
        readCheck = tetris_check_lines();

        if (enum_gameover == readCheck)
        {
            if (!runOnce)
            {
                runOnce = true;
                window.clear(Color::Black);
                s_gameOver.setTextureRect(IntRect(0, 0, 288, 294));
                s_gameOver.setPosition(0, 0);
                window.draw(s_gameOver);
                window.display();
                gameOverSound.setVolume(75);
                gameOverSound.play();
                lost = true;
            }
        }
        else
        {
            if (enum_line_complete == readCheck)
                gameLineSound.play();

            //---Draw---//
            window.clear(Color::White);
            window.draw(s_background);
            // draw and display the pixels
            for (int i = 0; i < H; i++)
            {
                for (int j = 0; j < W; j++)
                {
                    if (field[i][j] == 0)
                        continue;
                    s_tetris.setTextureRect(IntRect(field[i][j] * PXL, 0, PXL, PXL));
                    s_tetris.setPosition(j * PXL, i * PXL);
                    s_tetris.move(28, 31); // offset
                    window.draw(s_tetris);
                }
            }
            // draw and display the titre, colorNum is the same as the field[i][j] value
            for (int i = 0; i < 4; i++)
            {
                s_tetris.setTextureRect(IntRect(colorNum * PXL, 0, PXL, PXL));
                s_tetris.setPosition(a[i].x * PXL, a[i].y * PXL);
                s_tetris.move(28, 31); // offset
                window.draw(s_tetris);
            }
            window.display();
        }
    }
    return 0;
}
