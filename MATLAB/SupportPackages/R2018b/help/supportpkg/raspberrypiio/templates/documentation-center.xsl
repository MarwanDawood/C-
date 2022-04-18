<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE xsl:stylesheet [
  <!ENTITY nbsp "&#160;">
  <!ENTITY copy "&#169;">
]>
<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:file="java.io.File"
               xmlns:SimpleDateFormat="java.text.SimpleDateFormat"
               xmlns:Date="java.util.Date"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
               exclude-result-prefixes="file SimpleDateFormat Date xs">

  <!-- Copyright 2012-2018 MathWorks, Inc. -->
  
  <!-- To test this stylesheet:
    1. Start matlab from your sandbox, then issue the following:
         cd(fullfile(matlabroot,'makefiles'));
         gen_searchindex('WEB')
    2. Make a copy of documentation-center.html and name it index.html.
    3. Copy both documentation-center.html and index.html to both the  
       help and help\releases\CURRENTRELEASE folders in the applicable
       web integ area (e.g., \\mathworks\www\external-integ1\htdocs\). 
  -->

  <!-- Locale parameter - empty for English -->
  <xsl:param name="locale"/>
  <!-- Destination parameter - "web_dc1", "web", or "install" -->
  <xsl:param name="destination"/>
  <!-- Phase of the current release (g835949) is set in the file matlab/help/templates/release_info.txt -->
  <xsl:param name="phaseoftherelease"/>
  <!-- File containing American English strings -->
  <xsl:variable name="en_US_StringFile" select="'strings_en_US.xml'"/>
  <!-- File containing translated strings for the current non-English locale -->
  <xsl:variable name="localized_StringFile" select="concat('strings_', $locale, '.xml')"/>
  <!-- Release version (g835949) -->
  <xsl:param name="releaseversion"/>
  <!-- Copyright year (g914730) -->
  <xsl:variable name="copyrightYear" select="substring($releaseversion,2,4)"/>
  <xsl:variable name="releaseversionlc" select="translate($releaseversion,'R','r')"/>
  <!-- Output location -->
  <xsl:param name="docRoot"/>
  <!-- Generate index-not-found page - 'yes' or empty (g865491) -->
  <xsl:param name="generate_index_not_found_page"/>
  
  <xsl:variable name="sdf" select="SimpleDateFormat:new('yyyyMMddHHmm')"/>
  <xsl:variable name="datetime" select="Date:new()"/>
  <xsl:variable name="todaystimestamp" select="SimpleDateFormat:format($sdf, $datetime)"/>
  <xsl:output method="html" indent="yes" encoding="UTF-8" />

  <xsl:key name="prod_categories" match="group" use="text()"/>
  
  <xsl:template match="/documentation-set">
    <!-- Exclude 'install' because it is already linked to in the navigation head -->
    <!-- Exclude 'sb2sl' per g812954 -->
    <xsl:variable name="nodes" select="product-list/product[not((child::short-name='install') or (child::short-name='sb2sl'))]"/>
    <xsl:variable name="addons" select="addon-list/addon"/>
    <xsl:variable name="rounded_mid" select="round(count($nodes) div 2)"/>
    <xsl:choose>
      <xsl:when test="$destination = 'web'">
        <xsl:call-template name="web_page_nextgen">
          <xsl:with-param name="nodes" select="$nodes"/>
          <xsl:with-param name="rounded_mid" select="$rounded_mid"/>
          <xsl:with-param name="addons" select="$addons"/>
          <xsl:with-param name="generate_index_not_found_page" select="$generate_index_not_found_page"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="install_page_nextgen">
          <xsl:with-param name="nodes" select="$nodes"/>
          <xsl:with-param name="rounded_mid" select="$rounded_mid"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="install_page_nextgen">
    <xsl:param name="nodes"/>
    <xsl:param name="rounded_mid"/>
    <xsl:text disable-output-escaping="yes">&#x3C;!DOCTYPE HTML&#x3E;&#x0A;</xsl:text>
    <html>
      <head>
        <title><xsl:text>MATLAB </xsl:text>
          <xsl:call-template name="getString">
            <xsl:with-param name="key" select="'documentation_center'"/>
          </xsl:call-template>
        </title>
        <xsl:comment>New family/group layout</xsl:comment>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        
        <link href="includes/product/css/bootstrap.min.css" rel="stylesheet" type="text/css"/>
        <link href="includes/product/css/site6.css" rel="stylesheet" type="text/css"/>
        <link href="includes/product/css/site6_lg.css" rel="stylesheet" media="screen and (min-width: 1200px)"/>
        <link href="includes/product/css/site6_md.css" rel="stylesheet" media="screen and (min-width: 992px) and (max-width: 1199px)"/>
        <link href="includes/product/css/site6_sm+xs.css" rel="stylesheet" media="screen and (max-width: 991px)"/>
        <link href="includes/product/css/site6_sm.css" rel="stylesheet" media="screen and (min-width: 768px) and (max-width: 991px)"/>
        <link href="includes/product/css/site6_xs.css" rel="stylesheet" media="screen and (max-width: 767px)"/>
        <link href="includes/product/css/site6_offcanvas.css" rel="stylesheet" type="text/css"/><xsl:text>&#x0A;</xsl:text>          
        <script src="includes/product/scripts/jquery/jquery-latest.js"></script><xsl:text>&#x0A;</xsl:text>
        <script src="includes/product/scripts/jquery/jquery.mobile.custom.min.js"></script><xsl:text>&#x0A;</xsl:text>
        <script src="includes/product/scripts/bootstrap.min.js"></script><xsl:text>&#x0A;</xsl:text>
        <script src="includes/product/scripts/underscore-min.js"></script><xsl:text>&#x0A;</xsl:text>
        <script src="includes/product/scripts/hspresolution.js"></script><xsl:text>&#x0A;</xsl:text>
        <script src="includes/product/scripts/suggest.js"></script><xsl:text>&#x0A;</xsl:text>
        <script src="includes/product/scripts/global.js"></script><xsl:text>&#x0A;</xsl:text>
        <script src="includes/product/scripts/productfilter.js"></script><xsl:text>&#x0A;</xsl:text>
        <script src="includes/shared/scripts/f1help.js"></script><xsl:text>&#x0A;</xsl:text>
        <script src="includes/shared/scripts/helpservices.js"></script><xsl:text>&#x0A;</xsl:text>
        <style>
          .family_container.off {display:none;}
          .product_group.off {display:none;}
        </style><xsl:text>&#x0A;</xsl:text>
        <script type="text/javascript">
          <![CDATA[
function setVisibility() {
  var prodFilterData = {};
  var services = {
    "messagechannel":"prodfilter",
    "requesthandler":"productfilter:handleSelectedProducts|handleSelectedAddOns|handleCustomToolboxes",
    "webservice":null
  };

  requestHelpService(prodFilterData, services, function(data) {
    var prodList = $.parseJSON(data.prodlist);
    var prodNavList = $.parseJSON(data.prodnavlist);
    var addOnList = $.parseJSON(data.addonlist);
    var toolboxList = $.parseJSON(data.toolboxlist);
    handleSelectedProducts(prodList, prodNavList);
    handleSelectedAddOns(addOnList);
    handleCustomToolboxes(toolboxList);
  });
}

function handleSelectedProducts(prodList, prodNavList) {
    handleComingFromProductList(prodNavList, 'all_product_list', 'all_products');
    jQuery.each(prodList, function(index,value) {
        var prodElements = $("."+value+"-link");
        prodElements.show();
        prodElements.closest('.family_container').removeClass('off');
        prodElements.closest('.product_group').removeClass('off');
    });
}

function handleSelectedAddOns(addOnList) {
    handleSelectedNonProducts(addOnList, "sp-links", "addon_list");
}

function handleCustomToolboxes(toolboxList) {
    handleProductList(toolboxList, 'supp_software_list', 'supp_software');
    handleSelectedNonProducts(toolboxList, "3p-links", "3p_list");
}

function handleSelectedNonProducts(nonProdList, linkClass, listClass) {
  if (nonProdList.length > 0) {
    var links = $("."+linkClass);
    for(var i=0; i<links.length; i++){
        var link = links.eq(i);
        link.removeClass("support_package_list");
        link.closest('.family_container').removeClass('off');
    }
    var compiledTmpl = JST['installedHspTmpl']({installedhsps: nonProdList});
    var lists = $("."+listClass);
    for(var i=0; i<lists.length; i++){
        var list = lists.eq(i);
        list.append(compiledTmpl);
    }
  }
}

function adjustTopNavWidth(resetLinks) {
    if (resetLinks) {
        $("#topnav_more").hide();
        $("#topnav_more").removeClass("crux_nav_active");
        $("#topnav_more > ul > li").detach().appendTo("#topnav_main");
        var moreItem = $("#topnav_more").detach();
        $("#topnav_main").append(moreItem);
    } else {
        inspectTopNavLinks();
        $(window).resize(function() {
            adjustTopNavWidth(true);
        });
    }

    // The selected item should be selected if it gets added to the "More" menu.
    $("#topnav_main > li.crux_nav_active").addClass("active");

    var titleElt = $("div.section_header_title > h1");
    var headerArea = $("#section_header_title");
    var targetWidth = headerArea.width() - titleElt.width() - titleElt.offset().left - $("#topnav_more").width() - 5;
    
    var menuStart = -1;
    for (var i = 0; i < window.topnav_link_positions.length; i++) {
        if (window.topnav_link_positions[i] > targetWidth) {
            menuStart = i;
            break;
        }
    }
    
    if (menuStart >= 0) {
        var navItems = $("#topnav_main > li");
        navItems.slice(menuStart, navItems.length-1).detach().appendTo("#topnav_more > ul");
        if ($("#topnav_more > ul").find(".crux_nav_active").length > 0) {
            $("#topnav_more").addClass("crux_nav_active");
        }
        $("#topnav_more").show();
    }
}

function inspectTopNavLinks() {
    var navItems = $("#topnav_main > li");
    if (!navItems || navItems.length === 0) {
        window.topnav_link_positions = [];
        return;
    }

    var itemsLeft = $(navItems[0]).offset().left;
    var linkPositions = [];
    
    navItems.each(function(idx,item) {
        item = $(item);
        if (item.attr("id") === "topnav_more") {
            return false;
        }
        
        var widthToItem = item.offset().left + item.width() - itemsLeft;
        linkPositions.push(widthToItem);
    });
    
    window.topnav_link_positions = linkPositions;
}

$(setVisibility);
$(function() {adjustTopNavWidth(false);});
]]>
        </script><xsl:text>&#x0A;</xsl:text>
        <link href="includes/product/css/doc_center_base.css" rel="stylesheet" type="text/css"/>
        <link href="includes/product/css/doc_center_installed.css" rel="stylesheet" type="text/css"/>
        <xsl:if test="string-length($locale) &gt; 0">
          <link rel="stylesheet" type="text/css">
            <xsl:attribute name="href">
              <xsl:text>includes/product/css/doc_center_</xsl:text><xsl:value-of select="$locale"/><xsl:text>.css</xsl:text>
            </xsl:attribute>
          </link>
        </xsl:if>
        <link href="includes/product/css/doc_center_print.css" rel="stylesheet" type="text/css" media="print"/><xsl:text>&#x0A;</xsl:text>
        <meta name="generator" content="DocBook XSL Stylesheets V1.52.2"/>
        <meta http-equiv="Content-Script-Type" content="text/javascript"/>
        <meta name="toctype" content="cat"/>
        <!-- DOC SPECIFIC JS: START -->
        <!-- DOC SPECIFIC JS: END -->
      </head>
      
      <body id="responsive_offcanvas" class="doc_center_landing_pg">
        <!-- Conjoined Header: Start -->
        <div id="doc_header_spacer" class="header"></div>
        
        <!-- Start of top nav -->
        <xsl:variable name="relpathtohelptop" select="''"/>
        <!-- Conjoined Header: Start -->
        <div class="sticky_header_container includes_subnav affix-top"> 
          <!-- Section Header: Start -->
          <div class="section_header level_3">
            <div class="container-fluid">
              <div class="row" id="mobile_search_row">
                <div class="col-xs-12 has_horizontal_local_nav" id="section_header_title">
                  <div class="section_header_content">
                    <div class="section_header_title">
                      <h1>
                        <xsl:call-template name="getString">
                          <xsl:with-param name="key" select="'documentation_center'"/>
                        </xsl:call-template>
                      </h1>
                    </div>
                    <button type="button" class="navbar-toggle collapsed subnav visible-xs" data-toggle="collapse" data-target=".mobile_subnav_content"> <span class="icon-arrow-down icon_24"></span> </button>
                  </div>
                  <!-- CRUX Nav: START -->
                  <div class="crux_nav_container hidden-xs">
                    <div class="crux_nav">
                      <ul id="topnav_main">
                        <li class="crux_nav_active" id="crux_nav_documentation">
                          <a href="documentation-center.html">
                            <xsl:call-template name="getString">
                              <xsl:with-param name="key" select="'top_nav_documentation'"/>
                            </xsl:call-template>
                          </a>
                        </li>
                        <li id="crux_nav_example">
                          <a href="examples.html"><xsl:call-template name="getString"><xsl:with-param name="key" select="'top_nav_examples'"></xsl:with-param></xsl:call-template></a>
                        </li>
                        <li id="crux_nav_function">
                          <a href="referencelist.html?type=function"><xsl:call-template name="getString"><xsl:with-param name="key" select="'top_nav_functions'"></xsl:with-param></xsl:call-template></a>
                        </li>
                        <li id="crux_nav_block">
                          <a href="referencelist.html?type=block"><xsl:call-template name="getString"><xsl:with-param name="key" select="'top_nav_blocks'"></xsl:with-param></xsl:call-template></a>
                        </li>
                        <li id="crux_nav_app">
                          <a href="referencelist.html?type=app"><xsl:call-template name="getString"><xsl:with-param name="key" select="'top_nav_apps'"></xsl:with-param></xsl:call-template></a>
                        </li>
                        <li role="presentation" class="dropdown" id="topnav_more" style="display:none;">
                          <a class="dropdown-toggle" data-toggle="dropdown" href="#" role="button"
                            aria-haspopup="true" aria-expanded="false">
                            <xsl:call-template name="getString"><xsl:with-param name="key" select="'top_nav_more_dropdown'"></xsl:with-param></xsl:call-template>
                            <span class="caret"></span>
                          </a>
                          <ul class="dropdown-menu"></ul>
                        </li>
                        
                      </ul>
                    </div>
                  </div>
                  <!-- CRUX Nav: END --> 
                </div>
                <div class="col-xs-12" id="mobile_search">
                  <div class="search_nested_content_container">
                    <form id="docsearch_form" name="docsearch_form" method="get" data-language="en" action="templates/searchresults.html">
                      <xsl:attribute name="data-release">
                        <xsl:value-of select="$releaseversion"/>
                      </xsl:attribute>
                      <div class="input-group tokenized_search_field">
                        <label class="sr-only"><xsl:call-template name="getString"><xsl:with-param name="key" select="'search_help'"></xsl:with-param></xsl:call-template></label>
                        <input type="text" class="form-control conjoined_search" autocomplete="off" name="qdoc" id="docsearch">
                          <xsl:attribute name="placeholder"><xsl:call-template name="getString"><xsl:with-param name="key" select="'search_help'"></xsl:with-param></xsl:call-template></xsl:attribute>
                        </input>
                        <div class="input-group-btn">
                          <button disabled="" type="submit" name="submitsearch" id="submitsearch" class="btn icon-search btn_search_adjacent btn_search icon_16" tabindex="-1"></button>
                        </div>
                      </div>
                    </form>
                  </div>
                  <button class="btn icon-remove btn_search pull-right icon_32 visible-xs" data-toggle="collapse" href="#mobile_search" aria-expanded="false" aria-controls="mobile_search"></button>
                </div>
                <div class="visible-xs" id="search_actuator">
                  <button class="btn icon-search btn_search pull-right icon_16" data-toggle="collapse" href="#mobile_search" aria-expanded="false" aria-controls="mobile_search"></button>
                </div>
              </div>
              <!-- Section Header: End --> 
              <!-- Mobile Local Nav: Start -->
              <div class="row visible-xs" id="mobile_subnav">
                <div class="col-xs-12">
                  <div class="navbar-collapse collapse mobile_subnav_content"> 
                    <!-- CRUX Nav: START -->
                    <div class="crux_nav_container">
                      <div class="crux_nav">
                        <ul class="nav navbar-nav subnav">
                          <li class="crux_nav_active" id="crux_nav_documentation">
                            <a href="documentation-center.html">
                              <xsl:call-template name="getString">
                                <xsl:with-param name="key" select="'top_nav_documentation'"/>
                              </xsl:call-template>
                            </a>
                          </li>
                          <li id="crux_nav_example">
                            <a href="examples.html"><xsl:call-template name="getString"><xsl:with-param name="key" select="'top_nav_examples'"></xsl:with-param></xsl:call-template></a>
                          </li>
                          <li id="crux_nav_function">
                            <a href="referencelist.html?type=function"><xsl:call-template name="getString"><xsl:with-param name="key" select="'top_nav_functions'"></xsl:with-param></xsl:call-template></a>
                          </li>
                          <li id="crux_nav_block">
                            <a href="referencelist.html?type=block"><xsl:call-template name="getString"><xsl:with-param name="key" select="'top_nav_blocks'"></xsl:with-param></xsl:call-template></a>
                          </li>
                          <li id="crux_nav_app">
                            <a href="referencelist.html?type=app"><xsl:call-template name="getString"><xsl:with-param name="key" select="'top_nav_apps'"></xsl:with-param></xsl:call-template></a>
                          </li>
                        </ul>
                      </div>
                    </div>
                    <!-- CRUX Nav: END --> 
                  </div>
                </div>
              </div>
              <!-- Mobile Local Nav: End --> 
            </div>
          </div>
          <!-- Horo Nav: Start -->
          <div class="horizontal_nav">
            <div class="horizontal_nav_container">
              <div class="offcanvas_actuator" data-toggle="offcanvas" data-target="#sidebar" id="nav_toggle">
                <button type="button" class="btn"> <span class="sr-only">Toggle navigation</span> <span class="icon-menu"></span> </button>
                <span class="offcanvas_actuator_label" id="translation_icon-filter" tabindex="0"></span> <span class="offcanvas_actuator_close" tabindex="0"></span> </div>
              <div class="offcanvas_horizontal_nav">
                <div class="container-fluid">
                  <div class="row">
                    <div class="col-md-12 hidden-xs hidden-sm"></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <!-- Horo Nav: End --> 
        </div>
        <!-- Conjoined Header: End -->        
        <!-- End of top nav -->
        
        <div class="row-offcanvas row-offcanvas-left">
          <div class="sidebar-offcanvas" id="sidebar" role="navigation">
            <nav class="offcanvas_nav" role="navigation">
              <div id="all_products" style="display: none;">
                <h3><xsl:call-template name="getString"><xsl:with-param name="key" select="'category'"></xsl:with-param></xsl:call-template></h3>
                <ul class="nav_toc" id="all_product_list">
                </ul>
              </div>
              <div id="supp_software" style="display: none;">
                <h3><xsl:call-template name="getString"><xsl:with-param name="key" select="'supplemental_software'"></xsl:with-param></xsl:call-template></h3>
                <ul class="nav_toc" id="supp_software_list">
                </ul>
              </div>
            </nav> 
            <script src="includes/product/scripts/offcanvas.js"></script>
          </div>
          <div class="content_container" id="content_container">
            <div class="container-fluid">
              <div class="row">
                <div class="col-xs-12">
                  <xsl:if test="string-length($locale) &gt; 0">
                    <div class="landing_pg_intro">
                      <!-- This string should only be added for restricted doc -->
                      <xsl:if test="$locale='ko_KR' or $locale='zh_CN'">
                        <p>
                          <xsl:call-template name="getString">
                            <xsl:with-param name="key" select="'accessing_restricted_doc'"/>
                          </xsl:call-template>
                        </p>
                      </xsl:if>
                      <p>
                        <xsl:call-template name="getString">
                          <xsl:with-param name="key" select="'when_transl_doc_is_avail_you_will_see_it'"/>
                        </xsl:call-template>
                      </p>
                      <p>
                        <xsl:call-template name="getString">
                          <xsl:with-param name="key" select="'you_can_download_doc'"/>
                        </xsl:call-template>
                      </p>
                    </div>
                  </xsl:if>
                  <section id="doc_center_content" class="doc_center_landing">
                    <xsl:if test="contains($phaseoftherelease, 'beta') or contains($phaseoftherelease, 'prerelease')">
                      <div class="alert alert-info"> <span class="alert_icon icon-alert-info-reverse icon_32"></span>
                        <p><strong>Confidential Prerelease Documentation &#8212; Subject to Nondisclosure Agreement</strong></p>
                      </div>
                    </xsl:if>
                    <style>
                      #doc_center_content .panel-heading h2 { padding:0; margin:0; border:none; font-size: 18px; font-weight: normal;}
                    </style>
                    <div>
                      <ul class="list-inline">
                        <li>
                          <img class="pictogram_64">
                            <xsl:attribute name="src">
                              <xsl:value-of select="concat('includes/product/images/responsive/global/', $releaseversionlc, '.svg')"/>
                            </xsl:attribute>
                            <xsl:attribute name="alt"><xsl:value-of select="$releaseversion"/></xsl:attribute>
                          </img>
                          <br/>
                          <a href="relnotes/index.html">
                            <xsl:call-template name="getString">
                              <xsl:with-param name="key" select="'release_notes'"/>
                            </xsl:call-template>
                          </a>
                        </li>
                      </ul>
                      <div class="row add_margin_30">
                        <div class="col-xs-12 col-sm-4 family_container off"><span class="matlab-link"></span>
                          <div class="panel add_background_color_darkblue">
                            <div class="panel-body text-center"> <a href="matlab/index.html" class="svg_link"><img class="pictogram_wordmark" src="includes/product/images/responsive/global/matlab-white.svg" alt="MATLAB"/></a> </div>
                            <div class="panel-footer add_transparent_background_black_20 text-center"> <a href="matlab/index.html"><xsl:call-template name="getString"><xsl:with-param name="key" select="'explore_matlab'"></xsl:with-param></xsl:call-template></a> </div>
                          </div>
                        </div>
                        <div class="col-xs-12 col-sm-4 family_container off"><span class="simulink-link"></span>
                          <div class="panel add_background_color_darkblue">
                            <div class="panel-body text-center"> <a href="simulink/index.html" class="svg_link"><img class="pictogram_wordmark" src="includes/product/images/responsive/global/simulink-white.svg" alt="Simulink"/></a> </div>
                            <div class="panel-footer add_transparent_background_black_20 text-center"> <a href="simulink/index.html"><xsl:call-template name="getString"><xsl:with-param name="key" select="'explore_simulink'"></xsl:with-param></xsl:call-template></a> </div>
                          </div>
                        </div>
                        <div class="col-xs-12 col-sm-4">
                          <div class="panel add_background_color_mediumgray">
                            <div class="panel-body text-center"> <a href="install/index.html" class="svg_link"><img class="pictogram_100" src="includes/product/images/responsive/global/wrench-white.svg" alt="View Installation Help"/></a> </div>
                            <div class="panel-footer add_transparent_background_black_20 text-center"> <a href="install/index.html"><xsl:call-template name="getString"><xsl:with-param name="key" select="'view_installation_help'"></xsl:with-param></xsl:call-template></a> </div>
                          </div>
                        </div>
                    </div>
                    <div class="row">
                      <div class="col-xs-6">
                        <h2>
                          <xsl:call-template name="getString">
                            <xsl:with-param name="key" select="'applications'"/>
                          </xsl:call-template>
                        </h2>
                      </div>
                      <div class="col-xs-6">
                        <p class="text-right add_margin_0"><a><xsl:attribute name="href"><xsl:call-template name="getString"><xsl:with-param name="key" select="'edit_preferences_link'"></xsl:with-param></xsl:call-template></xsl:attribute><xsl:call-template name="getString"><xsl:with-param name="key" select="'edit_preferences'"></xsl:with-param></xsl:call-template></a></p>
                      </div>
                    </div>
                      <xsl:call-template name="build_product_list">
                        <xsl:with-param name="nodes" select="$nodes"/>
                      </xsl:call-template>
                    </div>
                  </section>
                </div>
              </div>
            </div>
          </div>
          
          <!-- MOBILE CTA - Begin -->
          <div class="cta_container_mobile visible-xs">
            <div class="container-fluid">
              <div class="row">
                <div class="col-xs-12">
                  <div class="cta_box">
                    <ul class="list-unstyled list-inline">
                      <li class="cta_item cta_item_general"><a href="examples.html" class="icon-examples"><xsl:call-template name="getString"><xsl:with-param name="key" select="'explore_examples'"></xsl:with-param></xsl:call-template></a></li>
                      <li class="cta_item cta_item_general"><a href="matlab:showAddonExplorer" class="icon-addons"><xsl:call-template name="getString"><xsl:with-param name="key" select="'explore_addons'"></xsl:with-param></xsl:call-template></a></li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <!-- MOBILE CTA - End -->
          
          <footer id="footer" class="bs-footer">
            <div class="container-fluid">
              <div class="footer">
                <div class="row">
                  <div class="col-xs-12"> 
                    
                    <!-- DOC CONTENT: START -->
                    
                    <p class="copyright">&copy; 1994-<xsl:value-of select="$copyrightYear"/> The MathWorks, Inc.</p>
                    <ul class="footernav">
                      <li class="footernav_trademarks">
                        <a href="MATLAB:web([docroot '/acknowledgments.html'])">
                          <xsl:call-template name="getString">
                            <xsl:with-param name="key" select="'acknowledgments'"/>
                          </xsl:call-template>
                        </a>
                      </li>
                      <li class="footernav_trademarks">
                        <a href="MATLAB:web([matlabroot '/trademarks.txt'])">
                          <xsl:call-template name="getString">
                            <xsl:with-param name="key" select="'trademarks'"/>
                          </xsl:call-template>
                        </a>
                      </li>
                      <li class="footernav_patents">
                        <a href="MATLAB:web([matlabroot '/patents.txt'])">
                          <xsl:call-template name="getString">
                            <xsl:with-param name="key" select="'patents'"/>
                          </xsl:call-template>
                        </a>
                      </li>
                      <li class="footernav_help">
                        <a href="MATLAB:web(matlab.internal.licenseAgreement)">
                          <xsl:call-template name="getString">
                            <xsl:with-param name="key" select="'terms_of_use'"/>
                          </xsl:call-template>
                        </a>
                      </li>
                    </ul>
                    
                    <!-- DOC CONTENT: END --> 
                    
                  </div>
                </div>
              </div>
            </div>
          </footer>
        </div>
      </body>
    </html>
  </xsl:template>
  
  <xsl:template name="build_product_list">
    <xsl:param name="nodes"/>
    <xsl:param name="hrefroot"/>
    <xsl:variable name="uniq_prod_categories" select="/documentation-set/product-list/product/product-family-list/product-family/group[generate-id(.)=generate-id(key('prod_categories', text()))]/text()"/>
    <div class="row">
      <div class="col-xs-12 col-sm-6">
        <div class="panel-group accordion accordion_variant_01" id="accordion_group_01" role="tablist" aria-multiselectable="true">
          <xsl:if test="$uniq_prod_categories[. = 'data-analytics-and-machine-learning']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'data-analytics-and-machine-learning'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'math-statistics-and-optimization']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'math-statistics-and-optimization'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'control-systems']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'control-systems'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'dsp-and-communications-systems']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'dsp-and-communications-systems'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'image-video-processing']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'image-video-processing'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'parallel-computing']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'parallel-computing'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'test-measurement']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'test-measurement'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'computational-finance']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'computational-finance'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'computational-biology']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'computational-biology'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </div>
      </div>
      <div class="col-xs-12 col-sm-6">
        <div class="panel-group accordion accordion_variant_01" id="accordion_group_02" role="tablist" aria-multiselectable="true">
          <xsl:if test="$uniq_prod_categories[. = 'event-based-modeling']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'event-based-modeling'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'physical-modeling']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'physical-modeling'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'code-generation']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'code-generation'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'desktop-web-deployment']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'desktop-web-deployment'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'rapid-prototyping']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'rapid-prototyping'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'verification-validation']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'verification-validation'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'database-access-and-reporting']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'database-access-and-reporting'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
          <xsl:if test="$uniq_prod_categories[. = 'simulation-graphics-and-reporting']">
            <xsl:call-template name="prod_category_accordion">
              <xsl:with-param name="prod_category" select="'simulation-graphics-and-reporting'"></xsl:with-param>
            </xsl:call-template>
          </xsl:if>
        </div>
      </div>
    </div>
    
    <div class="clearfix add_margin_40"></div>
    
    <div class="row">      
      <div class="col-xs-12 col-sm-6">
        <h3><xsl:call-template name="getString"><xsl:with-param name="key" select="'hardware_support'"></xsl:with-param></xsl:call-template></h3>
        <ul class="list-unstyled support_package_list sp-links family_container off">
          <div class="addon_list">
          </div>
        </ul>
        <ul class="list-unstyled">
          <div id="web_link">
            <xsl:choose>
              <xsl:when test="$destination = 'web'">
                <li class="coming_from_product in_product_hw_link"><xsl:call-template name="getString"><xsl:with-param name="key" select="'hardware_catalog_inproduct'"></xsl:with-param></xsl:call-template></li>
                <li class="not_coming_from_product system_browser_hw_link"><xsl:call-template name="getString"><xsl:with-param name="key" select="'hardware_catalog'"></xsl:with-param></xsl:call-template></li>
              </xsl:when>
              <xsl:otherwise>
                <li><xsl:call-template name="getString"><xsl:with-param name="key" select="'hardware_catalog_inproduct'"></xsl:with-param></xsl:call-template>
                </li>
              </xsl:otherwise>
            </xsl:choose>
          </div>
        </ul>
        <div class="family_container off">
          <h3 class="supp_software"><xsl:call-template name="getString"><xsl:with-param name="key" select="'supplemental_software'"></xsl:with-param></xsl:call-template></h3>
          <ul class="list-unstyled support_package_list 3p-links">
            <div class="3p_list">
              <xsl:if test="$destination = 'web'">
                <li class="product-link coming_from_product 3p-link"><a href="matlab:doc -classic"><xsl:call-template name="getString"><xsl:with-param name="key" select="'supplemental_software'"></xsl:with-param></xsl:call-template></a>
                </li>
              </xsl:if>
            </div>
          </ul>
        </div>
      </div>
      <xsl:if test="$destination = 'web' and $nodes[product-family-list/product-family[family/text() = 'webonlyproducts']]">
        <div class="col-xs-12 col-sm-6">
          <h3><xsl:call-template name="getString"><xsl:with-param name="key" select="'additional_products'"/></xsl:call-template></h3>
          <ul class="list-unstyled">
            <!-- This is where the web-only products go -->
            <xsl:for-each select="$nodes[product-family-list/product-family[family/text() = 'webonlyproducts']]">
              <xsl:call-template name="build_product_li">
                <xsl:with-param name="hrefroot" select="$hrefroot" />
              </xsl:call-template>
            </xsl:for-each>
          </ul>                
        </div>
      </xsl:if>
    </div>
  </xsl:template>
  
  <xsl:template name="prod_category_accordion">
    <xsl:param name="prod_category"></xsl:param>
    <xsl:variable name="panel_id" select="concat('prod_cat_', $prod_category)"/>
    <!-- Accordion Component: START -->
    <div class="panel panel-default product_group off">
      <div class="panel-heading add_cursor_pointer collapsed" role="tab" data-toggle="collapse" href="{concat('#', $panel_id)}" aria-expanded="false" aria-controls="{$panel_id}">
        <div class="panel-title"><!--<xsl:value-of select="$prod_category"/>--><xsl:call-template name="getString"><xsl:with-param name="key" select="$prod_category"></xsl:with-param></xsl:call-template></div>
      </div>
      <div id="{$panel_id}" class="panel-collapse collapse" role="tabpanel" aria-expanded="false">
        <div class="panel-body">
          <xsl:choose>
            <xsl:when test="key('prod_categories', $prod_category)/ancestor-or-self::product-family/family[text()='simulink'] and 
                            key('prod_categories', $prod_category)/ancestor-or-self::product-family/family[text()='matlab']">
              <xsl:call-template name="two_col_panel">
                <xsl:with-param name="prod_category" select="$prod_category"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="one_col_panel">
                <xsl:with-param name="prod_category" select="$prod_category"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </div>
      </div>
    </div>
    <!-- Accordion Component: END -->                                
  </xsl:template>
  
  <xsl:template name="one_col_panel">
    <xsl:param name="prod_category"/>
    <!--<p class="add_margin_10">Overview</p> TODO: Required design work to implement-->
    <ul class="list-unstyled add_list_spacing_3">
      <xsl:for-each select="key('prod_categories', $prod_category)/ancestor-or-self::product">
        <li><xsl:attribute name="class"><xsl:value-of select="concat('product-link ', short-name, '-link')"/></xsl:attribute>
          <a><xsl:attribute name="href"><xsl:value-of select="concat(./help-location, '/index.html')"/></xsl:attribute><xsl:apply-templates select="./display-name"></xsl:apply-templates>
            <xsl:if test="string-length($locale) &gt; 0">
              <xsl:variable name="localized_indexfile">
                <xsl:value-of select="$docRoot"/><xsl:text>/</xsl:text><xsl:value-of select="help-location"/><xsl:text>/index_</xsl:text><xsl:value-of select="$locale"/><xsl:text>.html</xsl:text>
              </xsl:variable>
              <xsl:if test="file:exists(file:new(string($localized_indexfile)))">
                <xsl:text> </xsl:text>
                <xsl:call-template name="getString">
                  <xsl:with-param name="key" select="'current_locale_in_parenthesis'"/>
                </xsl:call-template>
              </xsl:if>
            </xsl:if>
          </a>
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>  
  
  <xsl:template name="two_col_panel">
    <xsl:param name="prod_category"></xsl:param>
    <div class="row">
      <div class="col-xs-12 col-md-6 family_container off">
        <p class="add_margin_10">
          <xsl:call-template name="getString">
            <xsl:with-param name="key" select="'matlab_family'"/>
          </xsl:call-template>
        </p>
        <ul class="list-unstyled add_list_spacing_3">
            <xsl:for-each select="key('prod_categories', $prod_category)/self::group[preceding-sibling::family/text() = 'matlab']/ancestor::product">
            <li><xsl:attribute name="class"><xsl:value-of select="concat('product-link ', short-name, '-link')"/></xsl:attribute>
              <a><xsl:attribute name="href"><xsl:value-of select="concat(./help-location, '/index.html')"/></xsl:attribute><xsl:apply-templates select="./display-name"></xsl:apply-templates>
                <xsl:if test="string-length($locale) &gt; 0">
                  <xsl:variable name="localized_indexfile">
                    <xsl:value-of select="$docRoot"/><xsl:text>/</xsl:text><xsl:value-of select="help-location"/><xsl:text>/index_</xsl:text><xsl:value-of select="$locale"/><xsl:text>.html</xsl:text>
                  </xsl:variable>
                  <xsl:if test="file:exists(file:new(string($localized_indexfile)))">
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="getString">
                      <xsl:with-param name="key" select="'current_locale_in_parenthesis'"/>
                    </xsl:call-template>
                  </xsl:if>
                </xsl:if>
              </a>
            </li>
          </xsl:for-each>
        </ul>
      </div>
      <div class="col-xs-12 col-md-6 family_container off">
        <p class="add_margin_10">
          <xsl:call-template name="getString">
            <xsl:with-param name="key" select="'simulink_family'"/>
          </xsl:call-template>
        </p>
        <ul class="list-unstyled add_list_spacing_3">          
          <xsl:for-each select="key('prod_categories', $prod_category)/self::group[preceding-sibling::family/text() = 'simulink']/ancestor::product">
            <li><xsl:attribute name="class"><xsl:value-of select="concat('product-link ', short-name, '-link')"/></xsl:attribute>
              <a><xsl:attribute name="href"><xsl:value-of select="concat(./help-location, '/index.html')"/></xsl:attribute><xsl:apply-templates select="./display-name"></xsl:apply-templates>
                <xsl:if test="string-length($locale) &gt; 0">
                  <xsl:variable name="localized_indexfile">
                    <xsl:value-of select="$docRoot"/><xsl:text>/</xsl:text><xsl:value-of select="help-location"/><xsl:text>/index_</xsl:text><xsl:value-of select="$locale"/><xsl:text>.html</xsl:text>
                  </xsl:variable>
                  <xsl:if test="file:exists(file:new(string($localized_indexfile)))">
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="getString">
                      <xsl:with-param name="key" select="'current_locale_in_parenthesis'"/>
                    </xsl:call-template>
                  </xsl:if>
                </xsl:if>
              </a>
            </li>
          </xsl:for-each>
        </ul>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template name="build_product_li">
    <xsl:param name="hrefroot" />
    <!-- assumes we are processing a product node -->
    <li class="product-link">
      <xsl:attribute name="class">
        <xsl:value-of select="concat('product-link ', short-name, '-link')"/>
      </xsl:attribute>
      <xsl:attribute name="id">
        <xsl:value-of select="short-name"/><xsl:text>-link</xsl:text>
      </xsl:attribute>
      <a>
        <xsl:attribute name="href">
          <xsl:value-of select="$hrefroot"/><xsl:value-of select="help-location"/><xsl:text>/index.html</xsl:text>
        </xsl:attribute>
        <xsl:if test="string(display-name) = 'MATLAB Production Server'">
          <xsl:attribute name="class">not_coming_from_product</xsl:attribute>
        </xsl:if>
        <xsl:value-of select="display-name"/>
        <xsl:if test="string-length($locale) &gt; 0">
          <xsl:variable name="localized_indexfile">
            <xsl:value-of select="$docRoot"/><xsl:text>/</xsl:text><xsl:value-of select="help-location"/><xsl:text>/index_</xsl:text><xsl:value-of select="$locale"/><xsl:text>.html</xsl:text>
          </xsl:variable>
          <xsl:if test="file:exists(file:new(string($localized_indexfile)))">
            <xsl:text> </xsl:text>
            <xsl:call-template name="getString">
              <xsl:with-param name="key" select="'current_locale_in_parenthesis'"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:if>
      </a>
    </li>
  </xsl:template>
  
  <xsl:template name="web_page_nextgen">
    <xsl:param name="nodes"/>
    <xsl:param name="rounded_mid"/>
    <xsl:param name="addons"/>
    <xsl:param name="generate_index_not_found_page"/>
    <xsl:variable name="hrefroot">
      <xsl:choose>
        <xsl:when test="$generate_index_not_found_page='yes'">/help/</xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:variable>
    <xsl:text disable-output-escaping="yes">&#x3C;@html layout="responsive_offcanvas" layoutStyle="responsive"&#x3E;&#x0A;</xsl:text>
    <xsl:text disable-output-escaping="yes">&#x3C;@layoutComponents.options body_trail="true" crux_nav="true" fluid="true" contact_widget="false"/&#x3E;&#x0A;</xsl:text>
    <xsl:text disable-output-escaping="yes">&#x3C;@layoutComponents.micro_data "http://www.mathworks.com/help/schema/MathWorksDocPage"/&#x3E;&#x0A;</xsl:text>
    <xsl:text disable-output-escaping="yes">&#x3C;@layoutComponents.release number="</xsl:text><xsl:value-of select="$releaseversion"/><xsl:text disable-output-escaping="yes">"/&#x3E;&#x0A;</xsl:text>
    <xsl:text disable-output-escaping="yes">&#x3C;@layoutComponents.doc_search action="search.html"/&#x3E;&#x0A;</xsl:text>
      <xsl:text disable-output-escaping="yes">&#x3C;@head&#x3E;&#x0A;</xsl:text>
        <xsl:text disable-output-escaping="yes">&#x3C;@title&#x3E;MATLAB Documentation&#x3C;/@title&#x3E;&#x0A;</xsl:text>
        <meta name="generator" content="DocBook XSL Stylesheets V1.52.2"/>
        <meta http-equiv="Content-Script-Type" content="text/javascript"/>
        <meta name="toctype" content="cat"/><xsl:text disable-output-escaping="yes">&#x0A;</xsl:text>
    <script src="/help/releases/{$releaseversion}/includes/shared/scripts/l10n.js?{$todaystimestamp}"></script><xsl:text disable-output-escaping="yes">&#x0A;</xsl:text>
    <script src="/help/releases/{$releaseversion}/basecodes.js?{$todaystimestamp}"></script><xsl:text disable-output-escaping="yes">&#x0A;</xsl:text>
    <script src="/help/releases/{$releaseversion}/includes/product/scripts/underscore-min.js?{$todaystimestamp}"></script><xsl:text disable-output-escaping="yes">&#x0A;</xsl:text>
    <script src="/help/releases/{$releaseversion}/includes/product/scripts/hspresolution.js?{$todaystimestamp}"></script><xsl:text disable-output-escaping="yes">&#x0A;</xsl:text>
    <script src="/help/releases/{$releaseversion}/includes/product/scripts/productfilter.js?{$todaystimestamp}"></script><xsl:text disable-output-escaping="yes">&#x0A;</xsl:text>
    <script src="/help/releases/{$releaseversion}/includes/shared/scripts/helpservices.js?{$todaystimestamp}"></script><xsl:text disable-output-escaping="yes">&#x0A;</xsl:text>
    <xsl:text disable-output-escaping="yes">&#x3C;#include "doc_header1a_dcntr.html"&#x3E;&#x0A;</xsl:text>
    <style>
      .family_container.off {display:none;}
      .product_group.off {display:none;}
    </style><xsl:text disable-output-escaping="yes">&#x0A;</xsl:text>
    <script type="text/javascript">
      <![CDATA[
      
function handleSelectedProducts(prodList) {
    if (prodList == null || prodList.length == 0) {
        showAllProducts('.family_container', '.product_group');
        addClass('.3p-link', 'not_coming_from_product');
        removeClass('.3p-link', 'coming_from_product');
        hideNonProductList('.3p-links');
    } else {
        jQuery.each(prodList, function(index,value) {
          var prodElements = $("."+value+"-link");
          showProduct("."+value+"-link", '.family_container', '.product_group');
          if (value === "3p") {
              showNonProductList('.3p-links');
              $('#supp_software').show();                  
          }
        });
    }
    loadLeftNavFromJSON(prodList);
}

function handleSelectedAddOns(addOnList) {
    if (addOnList != null) {
        showNonProductList('.sp-links');
        jQuery.each(addOnList, function(index,value) {
            showProduct("."+value+"-link", '.family_container', '.product_group');
        });
    }
}

function showProduct(productID, containerID, groupID) {
    var prodElements = $(productID);
    prodElements.show();
    prodElements.closest(containerID).removeClass('off');
    if (groupID != null && groupID.length > 0) {
        prodElements.closest(groupID).removeClass('off');
    }
}

function showAllProducts(containerID, groupID) {
    var prodElements = $('.product-link');
    prodElements.show();
    var container = prodElements.closest(containerID);
    if (!!container) {
        container.removeClass('off');
    }
    if (groupID != null && groupID.length > 0) {
        prodElements.closest(groupID).removeClass('off');
    }
}

function addClass(linkID, className) {
    var links = $(linkID);
    for(var i=0; i<links.length; i++){
        var link = links.eq(i);
        link.addClass(className);
    }
}

function removeClass(linkID, className) {
    var links = $(linkID);
    for(var i=0; i<links.length; i++){
        var link = links.eq(i);
        link.removeClass(className);
    }
}

function hideNonProductList(linkID) {
    var links = $(linkID);
    for(var i=0; i<links.length; i++){
        var link = links.eq(i);
        link.addClass("support_package_list");
        link.closest('.family_container').addClass('off');
    }
}

function showNonProductList(linkID) {
    var links = $(linkID);
    for(var i=0; i<links.length; i++){
        var link = links.eq(i);
        link.removeClass("support_package_list");
        link.closest('.family_container').removeClass('off');
    }
}

function loadLeftNavFromJSON(selectedProductList) {
    'use strict';
    $.getJSON('all_product_doc.json', function (allProductJson) {
        if (selectedProductList == null || selectedProductList.length == 0) {
            handleProductList(allProductJson, 'all_product_list', 'all_products');
        } else {
            var filteredJson = allProductJson.filter(function (obj) {
                if ('shortname' in obj) {
                    for (var i = 0; i < selectedProductList.length; i++) {
                        if (selectedProductList[i] === obj.shortname) {
                            return true;
                        }
                    }
                    return false;
                } else {
                    return false;
                }
            });
            handleComingFromProductList(filteredJson, 'all_product_list', 'all_products');
        }
    });        
}

$(setVisibility);
]]>
        </script>
      <xsl:text disable-output-escaping="yes">&#x0A;&#x3C;/@head&#x3E;&#x0A;</xsl:text>
      <xsl:text disable-output-escaping="yes">&#x3C;@body&#x3E;&#x0A;</xsl:text>
      <xsl:text disable-output-escaping="yes">&#x3C;@contentComponents.off_canvas&#x3E;&#x0A;</xsl:text>
       <ul class="nav_breadcrumb">
         <li class="support_breadcrumb">
           <a href="/support">
             <xsl:call-template name="getString">
               <xsl:with-param name="key" select="'all_support'"/>
             </xsl:call-template>
           </a>
         </li>
       </ul>
       
       <xsl:variable name="prod_doc_url">
        <xsl:choose>
          <xsl:when test="$generate_index_not_found_page='yes'">
            <xsl:value-of select="concat($hrefroot, 'index.html')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>#responsive_offcanvas</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
       </xsl:variable>
       <h3 class="add_font_color_darkgray">
         <xsl:call-template name="getString">
           <xsl:with-param name="key" select="'category'"/>
         </xsl:call-template>
       </h3>
       <ul class="nav_toc list-unstyled" id="all_product_list">
         <!--<li class="active"><a href="{$prod_doc_url}">
           <xsl:text disable-output-escaping="yes">&#x0A;&#x3C;#if docTemplate?default("N/A") == "PRODUCT" &#x7C;&#x7C; docTemplate?default("N/A") == "ONLINE"&#x3E;&#x0A;</xsl:text>
           <xsl:call-template name="getString"><xsl:with-param name="key" select="'category'"></xsl:with-param></xsl:call-template>
           <xsl:text disable-output-escaping="yes">&#x0A;&#x3C;#else&#x3E;&#x0A;</xsl:text>
           <xsl:call-template name="getString"><xsl:with-param name="key" select="'category'"></xsl:with-param></xsl:call-template>
           <xsl:text disable-output-escaping="yes">&#x0A;&#x3C;/#if&#x3E;&#x0A;</xsl:text>
         </a></li>-->
       </ul>
       <xsl:text disable-output-escaping="yes">&#x3C;#if docTemplate?default("N/A") == "PRODUCT"&#x3E;</xsl:text>
       <ul class="nav_toc coming_from_product" id="supp_software_list">
         <li style="display: list-item;"><a href="matlab:doc -classic"><xsl:call-template name="getString"><xsl:with-param name="key" select="'supplemental_software'"></xsl:with-param></xsl:call-template></a></li>
       </ul>
       <xsl:text disable-output-escaping="yes">&#x3C;/#if&#x3E;</xsl:text>
      <xsl:text disable-output-escaping="yes">&#x0A;&#x3C;/@contentComponents.off_canvas&#x3E;&#x0A;</xsl:text>
      <!--<div class="coming_from_product">
      <xsl:text disable-output-escaping="yes">
      &#x3C;@designComponents.pageHeaderContent link="/help"&#x3E;
        &#x3C;h1&#x3E;</xsl:text>
        <xsl:call-template name="getString">
          <xsl:with-param name="key" select="'documentation_center'"/>
        </xsl:call-template>
        <xsl:text disable-output-escaping="yes">&#x3C;/h1&#x3E;
          &#x3C;@designComponents.pageHeaderSearch&#x3E; &#x3C;#include "includes/web/html/doc_search.html"&#x3E; &#x3C;/@designComponents.pageHeaderSearch&#x3E;
           &#x3C;/@designComponents.pageHeaderContent&#x3E;
           &#x3C;@designComponents.ctabox orientation="horizontal"&#x3E;
             &#x3C;@designComponents.ctabox_item name="</xsl:text><xsl:call-template name="getString"><xsl:with-param name="key" select="'explore_examples'"></xsl:with-param></xsl:call-template><xsl:text disable-output-escaping="yes">" action="examples.html"/&#x3E;
             &#x3C;@designComponents.ctabox_item name="</xsl:text><xsl:call-template name="getString"><xsl:with-param name="key" select="'explore_addons'"></xsl:with-param></xsl:call-template><xsl:text disable-output-escaping="yes">" action="matlab:showAddonExplorer"/&#x3E;
           &#x3C;/@designComponents.ctabox&#x3E;
           &#x3C;@local_nav&#x3E;&#x3C;/@local_nav&#x3E;
        </xsl:text>
        </div>
    <div class="not_coming_from_product">-->
      <xsl:text disable-output-escaping="yes">
      &#x3C;@designComponents.pageHeaderContent link="/help"&#x3E;
        &#x3C;h1&#x3E;</xsl:text>
      <xsl:call-template name="getString">
        <xsl:with-param name="key" select="'documentation_center'"/>
      </xsl:call-template>
      
      <!-- The @designComponents.ctabox_item name values on CJK pages SHOULD NOT be localized; they should always appear in English and will be translated by Equus. So, not using the getString function for them here. See g1442296. -->
      <xsl:text disable-output-escaping="yes">&#x3C;/h1&#x3E;
        &#x3C;@designComponents.pageHeaderCruxNav&#x3E;
          &#x3C;ul id="crux_nav_desktop"&#x3E;
            &#x3C;li class="crux_nav_active" id="crux_nav_documentation"&#x3E;
              &#x3C;a href="index.html"&#x3E;
      </xsl:text>
                <xsl:call-template name="getString">
                  <xsl:with-param name="key" select="'top_nav_documentation'"/>
                </xsl:call-template>
      <xsl:text disable-output-escaping="yes">
              &#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li id="crux_nav_example"&#x3E;
              &#x3C;a href="examples.html"&#x3E;
      </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_examples'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li id="crux_nav_function"&#x3E;
              &#x3C;a href="referencelist.html?type=function"&#x3E;
    </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_functions'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li id="crux_nav_block"&#x3E;
              &#x3C;a href="referencelist.html?type=block"&#x3E;
      </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_blocks'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li id="crux_nav_app"&#x3E;
              &#x3C;a href="referencelist.html?type=app"&#x3E;
    </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_apps'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li role="presentation" class="dropdown" id="topnav_more" style="display:none;"&#x3E;
              &#x3C;a class="dropdown-toggle" data-toggle="dropdown" href="#" role="button"
                aria-haspopup="true" aria-expanded="false"&#x3E;
    </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_more_dropdown'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">
                &#x3C;span class="caret"&#x3E;&#x3C;/span&#x3E;
              &#x3C;/a&#x3E;
              &#x3C;ul class="dropdown-menu"&#x3E;&#x3C;/ul&#x3E;
            &#x3C;/li&#x3E;
          &#x3C;/ul&#x3E;
        &#x3C;/@designComponents.pageHeaderCruxNav&#x3E;
        &#x3C;@designComponents.mobileCruxNav&#x3E;
          &#x3C;ul class="nav navbar-nav subnav"&#x3E;
            &#x3C;li class="crux_nav_active" id="crux_nav_documentation"&#x3E;
              &#x3C;a href="index.html"&#x3E;
    </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_documentation'"/>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">
              &#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li id="crux_nav_example"&#x3E;
              &#x3C;a href="examples.html"&#x3E;
      </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_examples'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li id="crux_nav_function"&#x3E;
              &#x3C;a href="referencelist.html?type=function"&#x3E;
    </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_functions'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li id="crux_nav_block"&#x3E;
              &#x3C;a href="referencelist.html?type=block"&#x3E;
      </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_blocks'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li id="crux_nav_app"&#x3E;
              &#x3C;a href="referencelist.html?type=app"&#x3E;
    </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_apps'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">&#x3C;/a&#x3E;
            &#x3C;/li&#x3E;
            &#x3C;li role="presentation" class="dropdown" id="topnav_more" style="display:none;"&#x3E;
              &#x3C;a class="dropdown-toggle" data-toggle="dropdown" href="#" role="button"
                aria-haspopup="true" aria-expanded="false"&#x3E;
    </xsl:text>
    <xsl:call-template name="getString">
      <xsl:with-param name="key" select="'top_nav_more_dropdown'"></xsl:with-param>
    </xsl:call-template>
    <xsl:text disable-output-escaping="yes">
                &#x3C;span class="caret"&#x3E;&#x3C;/span&#x3E;
              &#x3C;/a&#x3E;
              &#x3C;ul class="dropdown-menu"&#x3E;&#x3C;/ul&#x3E;
            &#x3C;/li&#x3E;
          &#x3C;/ul&#x3E;
        &#x3C;/@designComponents.mobileCruxNav&#x3E;
          &#x3C;@designComponents.pageHeaderSearch&#x3E; &#x3C;#include "includes/web/html/doc_search.html"&#x3E; &#x3C;/@designComponents.pageHeaderSearch&#x3E;
           &#x3C;/@designComponents.pageHeaderContent&#x3E;
           &#x3C;#if docTemplate?default("N/A") == "PRODUCT"&#x3E;
           &#x3C;@designComponents.ctabox orientation="horizontal"&#x3E;
             &#x3C;@designComponents.ctabox_item name="Explore Examples" action="examples.html"/&#x3E;
             &#x3C;@designComponents.ctabox_item name="Explore Add-Ons" action="matlab:showAddonExplorer"/&#x3E;
           &#x3C;/@designComponents.ctabox&#x3E;
           &#x3C;#else&#x3E;
           &#x3C;@designComponents.ctabox orientation="horizontal"&#x3E;
              &#x3C;@designComponents.ctabox_item name="Trial Software" action="/programs/bounce/doc_tryit.html"/&#x3E;
              &#x3C;@designComponents.ctabox_item name="Product Updates" action="/support/web_downloads_bounce.html?s_cid=1008_degr_docdn_270055"/&#x3E;
           &#x3C;/@designComponents.ctabox&#x3E;
           &#x3C;/#if&#x3E;
           &#x3C;@local_nav&#x3E;&#x3C;/@local_nav&#x3E;
        </xsl:text>
        <!--</div>-->
        <xsl:if test="$generate_index_not_found_page='yes'">
          <p style="border:2px solid red; font-weight: bold; font-size: 11pt; padding: 10px;">
            <xsl:call-template name="getString">
              <xsl:with-param name="key" select="'page_not_avail'"/>
            </xsl:call-template>
            <xsl:call-template name="getString">
              <xsl:with-param name="key" select="'use_search_box_or_browse'"/>
            </xsl:call-template>
            <xsl:call-template name="getString">
              <xsl:with-param name="key" select="'view_archive_doc'"/>
            </xsl:call-template>
          </p>
        </xsl:if>
        <xsl:if test="string-length($locale) &gt; 0">
          <div class="landing_pg_intro">
            <p>
              <xsl:call-template name="getString">
                <xsl:with-param name="key" select="'transl_doc_is_avail_incr'"/>
              </xsl:call-template>
            </p>
            <p>
              <xsl:call-template name="getString">
                <xsl:with-param name="key" select="'you_can_download_doc'"/>
              </xsl:call-template>
            </p>
            <p>
              <xsl:call-template name="getString">
                <xsl:with-param name="key" select="'refer_to_other_releases'"/>
              </xsl:call-template>
            </p>
          </div>
        </xsl:if>
        <section id="doc_center_content" class="doc_center_landing">
          <xsl:if test="contains($phaseoftherelease, 'beta') or contains($phaseoftherelease, 'prerelease')">
            <div class="alert alert-info"> <span class="alert_icon icon-alert-info-reverse icon_32"></span>
              <p><strong>Confidential Prerelease Documentation &#8212; Subject to Nondisclosure Agreement</strong></p>
            </div>
          </xsl:if>
          <style>
            #doc_center_content .panel-heading h2 { padding:0; margin:0; border:none; font-size: 18px; font-weight: normal;}
          </style>
          <div class="not_coming_from_product">
            <div class="row add_margin_15">
              <div class="col-xs-6">
                <img class="pictogram_64">
                  <xsl:attribute name="src">
                    <xsl:value-of select="concat('/images/responsive/global/', $releaseversionlc, '.svg')"/>
                  </xsl:attribute>
                  <xsl:attribute name="alt"><xsl:value-of select="$releaseversion"/></xsl:attribute>
                </img>
                <br/>
                <a href="relnotes/index.html">
                  <xsl:call-template name="getString">
                    <xsl:with-param name="key" select="'release_notes'"/>
                  </xsl:call-template>
                </a>
                <span> | </span>
                <a href="/help/doc-archives.html">
                  <xsl:call-template name="getString">
                    <xsl:with-param name="key" select="'other_releases'"/>
                  </xsl:call-template>
                </a>
              </div><!--
              <div class="col-xs-6">
                <p class="text-right add_margin_0"><a href="/help/doc-archives.html"><xsl:call-template name="getString"><xsl:with-param name="key" select="'other_releases'"></xsl:with-param></xsl:call-template></a></p>
              </div>-->
            </div>
          </div>
          <div class="coming_from_product">
            <div class="row add_margin_15">
              <div class="col-xs-6">
                <img class="pictogram_64">
                  <xsl:attribute name="src">
                    <xsl:value-of select="concat('/images/responsive/global/', $releaseversionlc, '.svg')"/>
                  </xsl:attribute>
                  <xsl:attribute name="alt"><xsl:value-of select="$releaseversion"/></xsl:attribute>
                </img>
                <br/>
                <a href="relnotes/index.html">
                  <xsl:call-template name="getString">
                    <xsl:with-param name="key" select="'release_notes'"/>
                  </xsl:call-template>
                </a>
              </div>
            </div>
          </div>        
          <div class="row add_margin_30">
            <div class="col-xs-12 col-sm-4">
              <div class="panel add_background_color_darkblue">
                <div class="panel-body text-center"> <a href="matlab/index.html" class="svg_link"><img class="pictogram_wordmark" src="/images/responsive/global/matlab-white.svg" alt="MATLAB"/></a> </div>
                <div class="panel-footer add_transparent_background_black_20 text-center"> <a href="matlab/index.html"><xsl:call-template name="getString"><xsl:with-param name="key" select="'explore_matlab'"></xsl:with-param></xsl:call-template></a> </div>
              </div>
            </div>
            <div class="col-xs-12 col-sm-4">
              <div class="panel add_background_color_darkblue">
                <div class="panel-body text-center"> <a href="simulink/index.html" class="svg_link"><img class="pictogram_wordmark" src="/images/responsive/global/simulink-white.svg" alt="Simulink"/></a> </div>
                <div class="panel-footer add_transparent_background_black_20 text-center"> <a href="simulink/index.html"><xsl:call-template name="getString"><xsl:with-param name="key" select="'explore_simulink'"></xsl:with-param></xsl:call-template></a> </div>
              </div>
            </div>
            <div class="col-xs-12 col-sm-4">
              <div class="panel add_background_color_mediumgray">
                <div class="panel-body text-center"> <a href="install/index.html" class="svg_link"><img class="pictogram_100" src="/images/responsive/global/wrench-white.svg" alt="View Installation Help"/></a> </div>
                <div class="panel-footer add_transparent_background_black_20 text-center"> <a href="install/index.html"><xsl:call-template name="getString"><xsl:with-param name="key" select="'view_installation_help'"></xsl:with-param></xsl:call-template></a> </div>
              </div>
            </div>
          </div>
          <hr class="add_hr_spacing_10 add_margin_20"/>
          <div class="row">
            <div  class="col-xs-6">
              <h2>
                <xsl:call-template name="getString">
                  <xsl:with-param name="key" select="'applications'"/>
                </xsl:call-template>
              </h2>
            </div>
            <div class="coming_from_product">
              <div class="col-xs-6">
                <p class="text-right add_margin_0"><a><xsl:attribute name="href"><xsl:call-template name="getString"><xsl:with-param name="key" select="'edit_preferences_link'"></xsl:with-param></xsl:call-template></xsl:attribute><xsl:call-template name="getString"><xsl:with-param name="key" select="'edit_preferences'"></xsl:with-param></xsl:call-template></a></p>
              </div>
            </div>
          </div>
          <xsl:call-template name="build_product_list">
          <xsl:with-param name="nodes" select="$nodes"></xsl:with-param>
          <xsl:with-param name="hrefroot" select="$hrefroot" />
        </xsl:call-template>
        </section>
      <xsl:text disable-output-escaping="yes">&#x3C;/@body&#x3E;&#x0A;</xsl:text>
    <xsl:text disable-output-escaping="yes">&#x3C;/@html&#x3E;&#x0A;</xsl:text>
  </xsl:template>

  <!-- Return a string based on an input key -->
  <xsl:template name="getString">
    <xsl:param name="key"/>
    <xsl:param name="doe" select="false()" />
    
    <xsl:choose>
      <!-- First test if string is available in current locale, unless current locale is English -->
      <!-- Adding in the option to set disable-output-escaping to "yes". -->
      <xsl:when test="(string-length($locale) &gt; 0) and file:exists(file:new(concat($docRoot,'/templates/',$localized_StringFile))) and document($localized_StringFile)//string[@key=$key]" xmlns:file="java.io.File">
        <xsl:choose>
          <xsl:when test="$doe = false()">
            <xsl:copy-of select="document($localized_StringFile)//string[@key=$key]/node()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="document($localized_StringFile)//string[@key=$key]/node()" disable-output-escaping="yes"/>
          </xsl:otherwise>
        </xsl:choose>
        
      </xsl:when>
      <!-- Then test if string is available in the English string file -->
      <xsl:when test="file:exists(file:new(concat($docRoot,'/templates/',$en_US_StringFile))) and document($en_US_StringFile)//string[@key=$key]" xmlns:file="java.io.File">
        <xsl:copy-of select="document($en_US_StringFile)//string[@key=$key]/node()"/>
      </xsl:when>
      <!-- Otherwise return a warning message -->
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Warning: no string with key '</xsl:text>
          <xsl:value-of select="$key"/>
          <xsl:text>' found in string file for locale '</xsl:text>
          <xsl:value-of select="$locale"/>
          <xsl:text>' (empty if current locale is English) or English.</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:transform>
