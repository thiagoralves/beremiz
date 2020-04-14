<?xml version="1.0"?>
<xsl:stylesheet xmlns:func="http://exslt.org/functions" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:svg="http://www.w3.org/2000/svg" xmlns:str="http://exslt.org/strings" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:exsl="http://exslt.org/common" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:reflect="reflect" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ns="beremiz" xmlns:cc="http://creativecommons.org/ns#" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dc="http://purl.org/dc/elements/1.1/" extension-element-prefixes="ns func exsl regexp str dyn" version="1.0" exclude-result-prefixes="ns str regexp exsl func dyn reflect">
  <xsl:output method="xml" cdata-section-elements="xhtml:script"/>
  <xsl:variable name="hmi_elements" select="//svg:*[starts-with(@inkscape:label, 'HMI:')]"/>
  <xsl:variable name="hmitree" select="ns:GetHMITree()"/>
  <xsl:variable name="_categories">
    <noindex>
      <xsl:text>HMI_PLC_STATUS</xsl:text>
    </noindex>
    <noindex>
      <xsl:text>HMI_CURRENT_PAGE</xsl:text>
    </noindex>
  </xsl:variable>
  <xsl:variable name="categories" select="exsl:node-set($_categories)"/>
  <xsl:variable name="_indexed_hmitree">
    <xsl:apply-templates mode="index" select="$hmitree"/>
  </xsl:variable>
  <xsl:variable name="indexed_hmitree" select="exsl:node-set($_indexed_hmitree)"/>
  <xsl:template mode="index" match="*">
    <xsl:param name="index" select="0"/>
    <xsl:param name="parentpath" select="''"/>
    <xsl:variable name="content">
      <xsl:variable name="path">
        <xsl:choose>
          <xsl:when test="count(ancestor::*)=0">
            <xsl:text>/</xsl:text>
          </xsl:when>
          <xsl:when test="count(ancestor::*)=1">
            <xsl:text>/</xsl:text>
            <xsl:value-of select="@name"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$parentpath"/>
            <xsl:text>/</xsl:text>
            <xsl:value-of select="@name"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="not(local-name() = $categories/noindex)">
          <xsl:copy>
            <xsl:attribute name="index">
              <xsl:value-of select="$index"/>
            </xsl:attribute>
            <xsl:attribute name="hmipath">
              <xsl:value-of select="$path"/>
            </xsl:attribute>
            <xsl:for-each select="@*">
              <xsl:copy/>
            </xsl:for-each>
          </xsl:copy>
          <xsl:apply-templates mode="index" select="*[1]">
            <xsl:with-param name="index" select="$index + 1"/>
            <xsl:with-param name="parentpath">
              <xsl:value-of select="$path"/>
            </xsl:with-param>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="index" select="*[1]">
            <xsl:with-param name="index" select="$index"/>
            <xsl:with-param name="parentpath">
              <xsl:value-of select="$path"/>
            </xsl:with-param>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:copy-of select="$content"/>
    <xsl:apply-templates mode="index" select="following-sibling::*[1]">
      <xsl:with-param name="index" select="$index + count(exsl:node-set($content)/*)"/>
      <xsl:with-param name="parentpath">
        <xsl:value-of select="$parentpath"/>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>
  <xsl:template mode="parselabel" match="*">
    <xsl:variable name="label" select="@inkscape:label"/>
    <xsl:variable name="description" select="substring-after($label,'HMI:')"/>
    <xsl:variable name="_args" select="substring-before($description,'@')"/>
    <xsl:variable name="args">
      <xsl:choose>
        <xsl:when test="$_args">
          <xsl:value-of select="$_args"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$description"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="_type" select="substring-before($args,':')"/>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="$_type">
          <xsl:value-of select="$_type"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$args"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$type">
      <widget>
        <xsl:attribute name="id">
          <xsl:value-of select="@id"/>
        </xsl:attribute>
        <xsl:attribute name="type">
          <xsl:value-of select="$type"/>
        </xsl:attribute>
        <xsl:for-each select="str:split(substring-after($args, ':'), ':')">
          <arg>
            <xsl:attribute name="value">
              <xsl:value-of select="."/>
            </xsl:attribute>
          </arg>
        </xsl:for-each>
        <xsl:variable name="paths" select="substring-after($description,'@')"/>
        <xsl:for-each select="str:split($paths, '@')">
          <xsl:if test="string-length(.) &gt; 0">
            <path>
              <xsl:attribute name="value">
                <xsl:value-of select="."/>
              </xsl:attribute>
              <xsl:variable name="path" select="."/>
              <xsl:variable name="item" select="$indexed_hmitree/*[@hmipath = $path]"/>
              <xsl:if test="count($item) = 1">
                <xsl:attribute name="index">
                  <xsl:value-of select="$item/@index"/>
                </xsl:attribute>
                <xsl:attribute name="type">
                  <xsl:value-of select="local-name($item)"/>
                </xsl:attribute>
              </xsl:if>
            </path>
          </xsl:if>
        </xsl:for-each>
      </widget>
    </xsl:if>
  </xsl:template>
  <xsl:variable name="_parsed_widgets">
    <xsl:apply-templates mode="parselabel" select="$hmi_elements"/>
  </xsl:variable>
  <xsl:variable name="parsed_widgets" select="exsl:node-set($_parsed_widgets)"/>
  <func:function name="func:widget">
    <xsl:param name="id"/>
    <func:result select="$parsed_widgets/widget[@id = $id]"/>
  </func:function>
  <func:function name="func:is_descendant_path">
    <xsl:param name="descend"/>
    <xsl:param name="ancest"/>
    <func:result select="string-length($ancest) &gt; 0 and starts-with($descend,$ancest)"/>
  </func:function>
  <func:function name="func:same_class_paths">
    <xsl:param name="a"/>
    <xsl:param name="b"/>
    <xsl:variable name="class_a" select="$indexed_hmitree/*[@hmipath = $a]/@class"/>
    <xsl:variable name="class_b" select="$indexed_hmitree/*[@hmipath = $b]/@class"/>
    <func:result select="$class_a and $class_b and $class_a = $class_b"/>
  </func:function>
  <reflect:hmi-tree/>
  <xsl:template mode="testtree" match="*">
    <xsl:param name="indent" select="''"/>
    <xsl:value-of select="$indent"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text> </xsl:text>
    <xsl:for-each select="@*">
      <xsl:value-of select="local-name()"/>
      <xsl:text>="</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>" </xsl:text>
    </xsl:for-each>
    <xsl:text>
</xsl:text>
    <xsl:apply-templates mode="testtree" select="*">
      <xsl:with-param name="indent">
        <xsl:value-of select="concat($indent,'&gt;')"/>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>
  <xsl:template mode="debug" match="reflect:hmi-tree">
    <xsl:text>Raw HMI tree
</xsl:text>
    <xsl:apply-templates mode="testtree" select="$hmitree"/>
    <xsl:text>
</xsl:text>
    <xsl:text>Indexed HMI tree
</xsl:text>
    <xsl:apply-templates mode="testtree" select="$indexed_hmitree"/>
    <xsl:text>
</xsl:text>
    <xsl:text>Parsed Widgets
</xsl:text>
    <xsl:copy-of select="_parsed_widgets"/>
    <xsl:apply-templates mode="testtree" select="$parsed_widgets"/>
  </xsl:template>
  <xsl:variable name="geometry" select="ns:GetSVGGeometry()"/>
  <reflect:geometry/>
  <xsl:template mode="debug" match="reflect:geometry">
    <xsl:text>ID, x, y, w, h
</xsl:text>
    <xsl:for-each select="$geometry">
      <xsl:text> </xsl:text>
      <xsl:value-of select="@Id"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@x"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@y"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@w"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="@h"/>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
  </xsl:template>
  <func:function name="func:intersect_1d">
    <xsl:param name="a0"/>
    <xsl:param name="a1"/>
    <xsl:param name="b0"/>
    <xsl:param name="b1"/>
    <xsl:variable name="d0" select="$a0 &gt;= $b0"/>
    <xsl:variable name="d1" select="$a1 &gt;= $b1"/>
    <xsl:choose>
      <xsl:when test="not($d0) and $d1">
        <func:result select="3"/>
      </xsl:when>
      <xsl:when test="$d0 and not($d1)">
        <func:result select="2"/>
      </xsl:when>
      <xsl:when test="$d0 and $d1 and $a0 &lt; $b1">
        <func:result select="1"/>
      </xsl:when>
      <xsl:when test="not($d0) and not($d1) and $b0 &lt; $a1">
        <func:result select="1"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
  <func:function name="func:intersect">
    <xsl:param name="a"/>
    <xsl:param name="b"/>
    <xsl:variable name="x_intersect" select="func:intersect_1d($a/@x, $a/@x+$a/@w, $b/@x, $b/@x+$b/@w)"/>
    <xsl:choose>
      <xsl:when test="$x_intersect != 0">
        <xsl:variable name="y_intersect" select="func:intersect_1d($a/@y, $a/@y+$a/@h, $b/@y, $b/@y+$b/@h)"/>
        <func:result select="$x_intersect * $y_intersect"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
  <func:function name="func:overlapping_geometry">
    <xsl:param name="elt"/>
    <xsl:variable name="groups" select="/svg:svg | //svg:g"/>
    <xsl:variable name="g" select="$geometry[@Id = $elt/@id]"/>
    <xsl:variable name="candidates" select="$geometry[@Id != $elt/@id]"/>
    <func:result select="$candidates[(@Id = $groups/@id and (func:intersect($g, .) = 9)) or &#10;                          (not(@Id = $groups/@id) and (func:intersect($g, .) &gt; 0 ))]"/>
  </func:function>
  <xsl:variable name="hmi_pages_descs" select="$parsed_widgets/widget[@type = 'Page']"/>
  <xsl:variable name="hmi_pages" select="$hmi_elements[@id = $hmi_pages_descs/@id]"/>
  <xsl:variable name="keypads_descs" select="$parsed_widgets/widget[@type = 'Keypad']"/>
  <xsl:variable name="keypads" select="$hmi_elements[@id = $keypads_descs/@id]"/>
  <xsl:variable name="default_page">
    <xsl:choose>
      <xsl:when test="count($hmi_pages) &gt; 1">
        <xsl:choose>
          <xsl:when test="$hmi_pages_descs/arg[1]/@value = 'Home'">
            <xsl:text>Home</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="yes">No Home page defined!</xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="count($hmi_pages) = 0">
        <xsl:message terminate="yes">No page defined!</xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="func:widget($hmi_pages/@id)/arg[1]/@value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <func:function name="func:refered_elements">
    <xsl:param name="elems"/>
    <xsl:variable name="descend" select="$elems/descendant-or-self::svg:*"/>
    <xsl:variable name="clones" select="$descend[self::svg:use]"/>
    <xsl:variable name="originals" select="//svg:*[concat('#',@id) = $clones/@xlink:href]"/>
    <xsl:choose>
      <xsl:when test="$originals">
        <func:result select="$descend | func:refered_elements($originals)"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="$descend"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
  <func:function name="func:all_related_elements">
    <xsl:param name="page"/>
    <xsl:variable name="page_overlapping_geometry" select="func:overlapping_geometry($page)"/>
    <xsl:variable name="page_overlapping_elements" select="//svg:*[@id = $page_overlapping_geometry/@Id]"/>
    <xsl:variable name="page_sub_elements" select="func:refered_elements($page | $page_overlapping_elements)"/>
    <func:result select="$page_sub_elements"/>
  </func:function>
  <func:function name="func:required_elements">
    <xsl:param name="pages"/>
    <xsl:choose>
      <xsl:when test="$pages">
        <func:result select="func:all_related_elements($pages[1])&#10;                      | func:required_elements($pages[position()!=1])"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="/.."/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
  <xsl:variable name="required_elements" select="//svg:defs/descendant-or-self::svg:*&#10;       | func:required_elements($hmi_pages | $keypads)/ancestor-or-self::svg:*"/>
  <xsl:variable name="discardable_elements" select="//svg:*[not(@id = $required_elements/@id)]"/>
  <func:function name="func:sumarized_elements">
    <xsl:param name="elements"/>
    <xsl:variable name="short_list" select="$elements[not(ancestor::*/@id = $elements/@id)]"/>
    <xsl:variable name="filled_groups" select="$short_list/parent::svg:*[&#10;        not(descendant::*[&#10;            not(self::svg:g) and&#10;            not(@id = $discardable_elements/@id) and&#10;            not(@id = $short_list/descendant-or-self::*[not(self::svg:g)]/@id)&#10;        ])]"/>
    <xsl:variable name="groups_to_add" select="$filled_groups[not(ancestor::*/@id = $filled_groups/@id)]"/>
    <func:result select="$groups_to_add | $short_list[not(ancestor::svg:g/@id = $filled_groups/@id)]"/>
  </func:function>
  <func:function name="func:detachable_elements">
    <xsl:param name="pages"/>
    <xsl:choose>
      <xsl:when test="$pages">
        <func:result select="func:sumarized_elements(func:all_related_elements($pages[1]))&#10;                      | func:detachable_elements($pages[position()!=1])"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="/.."/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
  <xsl:variable name="_detachable_elements" select="func:detachable_elements($hmi_pages | $keypads)"/>
  <xsl:variable name="detachable_elements" select="$_detachable_elements[not(ancestor::*/@id = $_detachable_elements/@id)]"/>
  <xsl:variable name="forEach_widgets_ids" select="$parsed_widgets/widget[@type = 'ForEach']/@id"/>
  <xsl:variable name="forEach_widgets" select="$hmi_elements[@id = $forEach_widgets_ids]"/>
  <xsl:variable name="in_forEach_widget_ids" select="func:refered_elements($forEach_widgets)[not(@id = $forEach_widgets_ids)]/@id"/>
  <xsl:template mode="page_desc" match="svg:*">
    <xsl:variable name="desc" select="func:widget(@id)"/>
    <xsl:variable name="page" select="."/>
    <xsl:variable name="p" select="$geometry[@Id = $page/@id]"/>
    <xsl:variable name="page_all_elements" select="func:all_related_elements($page)"/>
    <xsl:variable name="all_page_widgets" select="$hmi_elements[@id = $page_all_elements/@id and @id != $page/@id]"/>
    <xsl:variable name="page_managed_widgets" select="$all_page_widgets[not(@id=$in_forEach_widget_ids)]"/>
    <xsl:variable name="page_relative_widgets" select="$page_managed_widgets[func:is_descendant_path(func:widget(@id)/path/@value, $desc/path/@value)]"/>
    <xsl:variable name="required_detachables" select="func:sumarized_elements($page_all_elements)/&#10;           ancestor-or-self::*[@id = $detachable_elements/@id]"/>
    <xsl:text>  "</xsl:text>
    <xsl:value-of select="$desc/arg[1]/@value"/>
    <xsl:text>": {
</xsl:text>
    <xsl:text>    widget: hmi_widgets["</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>"],
</xsl:text>
    <xsl:text>    bbox: [</xsl:text>
    <xsl:value-of select="$p/@x"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$p/@y"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$p/@w"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$p/@h"/>
    <xsl:text>],
</xsl:text>
    <xsl:if test="$desc/path/@value">
      <xsl:if test="count($desc/path/@index)=0">
        <xsl:message terminate="no">
          <xsl:text>Page id="</xsl:text>
          <xsl:value-of select="$page/@id"/>
          <xsl:text>" : No match for path "</xsl:text>
          <xsl:value-of select="$desc/path/@value"/>
          <xsl:text>" in HMI tree</xsl:text>
        </xsl:message>
      </xsl:if>
      <xsl:text>    page_index: </xsl:text>
      <xsl:value-of select="$desc/path/@index"/>
      <xsl:text>,
</xsl:text>
    </xsl:if>
    <xsl:text>    relative_widgets: [
</xsl:text>
    <xsl:for-each select="$page_relative_widgets">
      <xsl:text>        hmi_widgets["</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>"]</xsl:text>
      <xsl:if test="position()!=last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>    ],
</xsl:text>
    <xsl:text>    absolute_widgets: [
</xsl:text>
    <xsl:for-each select="$page_managed_widgets[not(@id = $page_relative_widgets/@id)]">
      <xsl:text>        hmi_widgets["</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>"]</xsl:text>
      <xsl:if test="position()!=last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>    ],
</xsl:text>
    <xsl:text>    jumps: [
</xsl:text>
    <xsl:for-each select="$parsed_widgets/widget[@id = $all_page_widgets/@id and @type='Jump']">
      <xsl:variable name="_id" select="@id"/>
      <xsl:variable name="opts">
        <xsl:call-template name="jump_widget_activity">
          <xsl:with-param name="hmi_element" select="$hmi_elements[@id=$_id]"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:if test="string-length($opts)&gt;0">
        <xsl:text>        hmi_widgets["</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text>"]</xsl:text>
        <xsl:if test="position()!=last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:text>
</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:text>    ],
</xsl:text>
    <xsl:text>    required_detachables: {
</xsl:text>
    <xsl:for-each select="$required_detachables">
      <xsl:text>        "</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>": detachable_elements["</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>"]</xsl:text>
      <xsl:if test="position()!=last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>    }
</xsl:text>
    <xsl:apply-templates mode="per_page_widget_template" select="$parsed_widgets/widget[@id = $all_page_widgets/@id]">
      <xsl:with-param name="page_desc" select="$desc"/>
    </xsl:apply-templates>
    <xsl:text>  }</xsl:text>
    <xsl:if test="position()!=last()">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:text>
</xsl:text>
  </xsl:template>
  <xsl:template mode="per_page_widget_template" match="*"/>
  <reflect:detachable-pages/>
  <xsl:template mode="debug" match="reflect:detachable-pages">
    <xsl:text>DETACHABLES:
</xsl:text>
    <xsl:for-each select="$detachable_elements">
      <xsl:text> </xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>In Foreach:
</xsl:text>
    <xsl:for-each select="$in_forEach_widget_ids">
      <xsl:text> </xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
  </xsl:template>
  <xsl:template mode="inline_svg" match="@* | node()">
    <xsl:if test="not(@id = $discardable_elements/@id)">
      <xsl:copy>
        <xsl:apply-templates mode="inline_svg" select="@* | node()"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>
  <xsl:template mode="inline_svg" match="svg:svg/@width"/>
  <xsl:template mode="inline_svg" match="svg:svg/@height"/>
  <xsl:template xmlns="http://www.w3.org/2000/svg" mode="inline_svg" match="svg:svg">
    <svg>
      <xsl:attribute name="preserveAspectRatio">
        <xsl:text>none</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="height">
        <xsl:text>100vh</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="width">
        <xsl:text>100vw</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates mode="inline_svg" select="@* | node()"/>
    </svg>
  </xsl:template>
  <xsl:template mode="inline_svg" match="svg:svg[@viewBox!=concat('0 0 ', @width, ' ', @height)]">
    <xsl:message terminate="yes">
      <xsl:text>ViewBox settings other than X=0, Y=0 and Scale=1 are not supported</xsl:text>
    </xsl:message>
  </xsl:template>
  <xsl:template mode="inline_svg" match="sodipodi:namedview[@units!='px' or @inkscape:document-units!='px']">
    <xsl:message terminate="yes">
      <xsl:text>All units must be set to "px" in Inkscape's document properties</xsl:text>
    </xsl:message>
  </xsl:template>
  <xsl:variable name="to_unlink" select="$hmi_elements[not(@id = $hmi_pages)]//svg:use"/>
  <xsl:template xmlns="http://www.w3.org/2000/svg" mode="inline_svg" match="svg:use">
    <xsl:choose>
      <xsl:when test="@id = $to_unlink/@id">
        <xsl:call-template name="unlink_clone"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates mode="inline_svg" select="@* | node()"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:variable name="_excluded_use_attrs">
    <name>
      <xsl:text>href</xsl:text>
    </name>
    <name>
      <xsl:text>width</xsl:text>
    </name>
    <name>
      <xsl:text>height</xsl:text>
    </name>
    <name>
      <xsl:text>x</xsl:text>
    </name>
    <name>
      <xsl:text>y</xsl:text>
    </name>
  </xsl:variable>
  <xsl:variable name="excluded_use_attrs" select="exsl:node-set($_excluded_use_attrs)"/>
  <xsl:template xmlns="http://www.w3.org/2000/svg" name="unlink_clone">
    <g>
      <xsl:for-each select="@*[not(local-name() = $excluded_use_attrs/name)]">
        <xsl:attribute name="{name()}">
          <xsl:value-of select="."/>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:variable name="targetid" select="substring-after(@xlink:href,'#')"/>
      <xsl:apply-templates mode="unlink_clone" select="//svg:*[@id = $targetid]">
        <xsl:with-param name="seed" select="@id"/>
      </xsl:apply-templates>
    </g>
  </xsl:template>
  <xsl:template xmlns="http://www.w3.org/2000/svg" mode="unlink_clone" match="@id">
    <xsl:param name="seed"/>
    <xsl:attribute name="id">
      <xsl:value-of select="$seed"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
  <xsl:template xmlns="http://www.w3.org/2000/svg" mode="unlink_clone" match="@*">
    <xsl:copy/>
  </xsl:template>
  <xsl:template xmlns="http://www.w3.org/2000/svg" mode="unlink_clone" match="svg:*">
    <xsl:param name="seed"/>
    <xsl:choose>
      <xsl:when test="@id = $hmi_elements/@id">
        <use>
          <xsl:attribute name="xlink:href">
            <xsl:value-of select="concat('#',@id)"/>
          </xsl:attribute>
        </use>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates mode="unlink_clone" select="@* | node()">
            <xsl:with-param name="seed" select="$seed"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:variable name="result_svg">
    <xsl:apply-templates mode="inline_svg" select="/"/>
  </xsl:variable>
  <xsl:variable name="result_svg_ns" select="exsl:node-set($result_svg)"/>
  <reflect:inline-svg/>
  <xsl:template mode="debug" match="reflect:inline-svg">
    <xsl:text>Unlinked :
</xsl:text>
    <xsl:for-each select="$to_unlink">
      <xsl:value-of select="@id"/>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
  </xsl:template>
  <xsl:template mode="hmi_elements" match="svg:*">
    <xsl:variable name="widget" select="func:widget(@id)"/>
    <xsl:variable name="eltid" select="@id"/>
    <xsl:text>  "</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>": {
</xsl:text>
    <xsl:text>    type: "</xsl:text>
    <xsl:value-of select="$widget/@type"/>
    <xsl:text>",
</xsl:text>
    <xsl:text>    args: [
</xsl:text>
    <xsl:for-each select="$widget/arg">
      <xsl:text>        "</xsl:text>
      <xsl:value-of select="@value"/>
      <xsl:text>"</xsl:text>
      <xsl:if test="position()!=last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>    ],
</xsl:text>
    <xsl:text>    offset: 0,
</xsl:text>
    <xsl:text>    indexes: [
</xsl:text>
    <xsl:for-each select="$widget/path">
      <xsl:choose>
        <xsl:when test="not(@index)">
          <xsl:message terminate="no">
            <xsl:text>Widget </xsl:text>
            <xsl:value-of select="$widget/@type"/>
            <xsl:text> id="</xsl:text>
            <xsl:value-of select="$eltid"/>
            <xsl:text>" : No match for path "</xsl:text>
            <xsl:value-of select="@value"/>
            <xsl:text>" in HMI tree</xsl:text>
          </xsl:message>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>        </xsl:text>
          <xsl:value-of select="@index"/>
          <xsl:text> /* </xsl:text>
          <xsl:value-of select="@value"/>
          <xsl:text> */ </xsl:text>
          <xsl:if test="position()!=last()">
            <xsl:text>,</xsl:text>
          </xsl:if>
          <xsl:text>
</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:text>    ],
</xsl:text>
    <xsl:text>    element: id("</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>"),
</xsl:text>
    <xsl:apply-templates mode="widget_defs" select="$widget">
      <xsl:with-param name="hmi_element" select="."/>
    </xsl:apply-templates>
    <xsl:apply-templates mode="widget_subscribe" select="$widget">
      <xsl:with-param name="hmi_element" select="."/>
    </xsl:apply-templates>
    <xsl:text>  }</xsl:text>
    <xsl:if test="position()!=last()">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:text>
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_subscribe" match="widget">
    <xsl:text>    sub: subscribe,
</xsl:text>
    <xsl:text>    unsub: unsubscribe,
</xsl:text>
    <xsl:text>    apply_cache: widget_apply_cache,
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_subscribe" match="widget[@type='Page']"/>
  <xsl:template name="defs_by_labels">
    <xsl:param name="labels" select="''"/>
    <xsl:param name="mandatory" select="'yes'"/>
    <xsl:param name="subelements" select="/.."/>
    <xsl:param name="hmi_element"/>
    <xsl:variable name="widget_type" select="@type"/>
    <xsl:for-each select="str:split($labels)">
      <xsl:variable name="name" select="."/>
      <xsl:variable name="elt" select="$result_svg_ns//*[@id = $hmi_element/@id]//*[@inkscape:label=$name][1]"/>
      <xsl:choose>
        <xsl:when test="not($elt/@id)">
          <xsl:if test="$mandatory='yes'">
            <xsl:message terminate="yes">
              <xsl:value-of select="$widget_type"/>
              <xsl:text> widget must have a </xsl:text>
              <xsl:value-of select="$name"/>
              <xsl:text> element</xsl:text>
            </xsl:message>
          </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>    </xsl:text>
          <xsl:value-of select="$name"/>
          <xsl:text>_elt: id("</xsl:text>
          <xsl:value-of select="$elt/@id"/>
          <xsl:text>"),
</xsl:text>
          <xsl:if test="$subelements">
            <xsl:text>    </xsl:text>
            <xsl:value-of select="$name"/>
            <xsl:text>_sub: {
</xsl:text>
            <xsl:for-each select="str:split($subelements)">
              <xsl:variable name="subname" select="."/>
              <xsl:variable name="subelt" select="$elt/*[@inkscape:label=$subname][1]"/>
              <xsl:choose>
                <xsl:when test="not($subelt/@id)">
                  <xsl:if test="$mandatory='yes'">
                    <xsl:message terminate="yes">
                      <xsl:value-of select="$widget_type"/>
                      <xsl:text> widget must have a </xsl:text>
                      <xsl:value-of select="$name"/>
                      <xsl:text>/</xsl:text>
                      <xsl:value-of select="$subname"/>
                      <xsl:text> element</xsl:text>
                    </xsl:message>
                  </xsl:if>
                  <xsl:text>        /* missing </xsl:text>
                  <xsl:value-of select="$name"/>
                  <xsl:text>/</xsl:text>
                  <xsl:value-of select="$subname"/>
                  <xsl:text> element */
</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>        "</xsl:text>
                  <xsl:value-of select="$subname"/>
                  <xsl:text>": id("</xsl:text>
                  <xsl:value-of select="$subelt/@id"/>
                  <xsl:text>")</xsl:text>
                  <xsl:if test="position()!=last()">
                    <xsl:text>,</xsl:text>
                  </xsl:if>
                  <xsl:text>
</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <xsl:text>    },
</xsl:text>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  <func:function name="func:escape_quotes">
    <xsl:param name="txt"/>
    <xsl:variable name="frst" select="substring-before($txt,'&quot;')"/>
    <xsl:variable name="frstln" select="string-length($frst)"/>
    <xsl:choose>
      <xsl:when test="$frstln &gt; 0 and string-length($txt) &gt; $frstln">
        <func:result select="concat($frst,'\&quot;',func:escape_quotes(substring-after($txt,'&quot;')))"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="$txt"/>
      </xsl:otherwise>
    </xsl:choose>
  </func:function>
  <xsl:template mode="widget_defs" match="widget[@type='Back']">
    <xsl:param name="hmi_element"/>
    <xsl:text>    on_click: function(evt) {
</xsl:text>
    <xsl:text>        if(jump_history.length &gt; 1){
</xsl:text>
    <xsl:text>           jump_history.pop();
</xsl:text>
    <xsl:text>           let [page_name, index] = jump_history.pop();
</xsl:text>
    <xsl:text>           switch_page(page_name, index);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    init: function() {
</xsl:text>
    <xsl:text>        this.element.setAttribute("onclick", "hmi_widgets['</xsl:text>
    <xsl:value-of select="$hmi_element/@id"/>
    <xsl:text>'].on_click(evt)");
</xsl:text>
    <xsl:text>    },
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_defs" match="widget[@type='Display']">
    <xsl:param name="hmi_element"/>
    <xsl:text>    frequency: 5,
</xsl:text>
    <xsl:text>    dispatch: function(value) {
</xsl:text>
    <xsl:choose>
      <xsl:when test="$hmi_element[self::svg:text]">
        <xsl:text>      this.element.textContent = String(value);
</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="no">
          <xsl:text>Display widget as a group not implemented</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>    },
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_defs" match="widget[@type='DropDown']">
    <xsl:param name="hmi_element"/>
    <xsl:call-template name="defs_by_labels">
      <xsl:with-param name="hmi_element" select="$hmi_element"/>
      <xsl:with-param name="labels">
        <xsl:text>text box button</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:text>    dispatch: function(value) {
</xsl:text>
    <xsl:text>        if(!this.opened) this.set_selection(value);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    init: function() {
</xsl:text>
    <xsl:text>        this.button_elt.setAttribute("onclick", "hmi_widgets['</xsl:text>
    <xsl:value-of select="$hmi_element/@id"/>
    <xsl:text>'].on_button_click()");
</xsl:text>
    <xsl:text>        this.text_bbox = this.text_elt.getBBox()
</xsl:text>
    <xsl:text>        this.box_bbox = this.box_elt.getBBox()
</xsl:text>
    <xsl:text>        lmargin = this.text_bbox.x - this.box_bbox.x;
</xsl:text>
    <xsl:text>        tmargin = this.text_bbox.y - this.box_bbox.y;
</xsl:text>
    <xsl:text>        this.margins = [lmargin, tmargin].map(x =&gt; Math.max(x,0));
</xsl:text>
    <xsl:text>        this.content = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
</xsl:text>
    <xsl:text>                        "eleven", "twelve", "thirteen", "fourteen", "fifteen"];
</xsl:text>
    <xsl:text>        //this.content = ["one", "two", "three", "four", "5", "6"];
</xsl:text>
    <xsl:text>        this.menu_offset = 0;
</xsl:text>
    <xsl:text>        this.lift = 0;
</xsl:text>
    <xsl:text>        this.opened = false;
</xsl:text>
    <xsl:text>        this.bound_inhibit_click_elsewhere = this.inhibit_click_elsewhere.bind(this);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_selection_click: function(selection) {
</xsl:text>
    <xsl:text>        console.log("selected "+selection);
</xsl:text>
    <xsl:text>        this.close();
</xsl:text>
    <xsl:text>        let orig = this.indexes[0];
</xsl:text>
    <xsl:text>        let idx = this.offset ? orig - this.offset : orig;
</xsl:text>
    <xsl:text>        apply_hmi_value(idx, selection);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_button_click: function() {
</xsl:text>
    <xsl:text>        this.open();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_backward_click:function(){
</xsl:text>
    <xsl:text>        this.move(false);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_forward_click:function(){
</xsl:text>
    <xsl:text>        this.move(true);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    set_selection: function(value) {
</xsl:text>
    <xsl:text>        this.text_elt.firstElementChild.textContent = 
</xsl:text>
    <xsl:text>          (value &gt;= 0 &amp;&amp; value &lt; this.content.length) ?
</xsl:text>
    <xsl:text>            this.content[value] : "?"+String(value)+"?";
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    grow_text: function(up_to) {
</xsl:text>
    <xsl:text>        let count = 1;
</xsl:text>
    <xsl:text>        let txt = this.text_elt; 
</xsl:text>
    <xsl:text>        let first = txt.firstElementChild;
</xsl:text>
    <xsl:text>        let bounds = svg_root.getBoundingClientRect(); 
</xsl:text>
    <xsl:text>        this.lift = 0;
</xsl:text>
    <xsl:text>        while(count &lt; up_to) {
</xsl:text>
    <xsl:text>            let next = first.cloneNode();
</xsl:text>
    <xsl:text>            next.removeAttribute("y");
</xsl:text>
    <xsl:text>            next.setAttribute("dy", "1.1em");
</xsl:text>
    <xsl:text>            next.textContent = "...";
</xsl:text>
    <xsl:text>            txt.appendChild(next);
</xsl:text>
    <xsl:text>            let rect = txt.getBoundingClientRect();
</xsl:text>
    <xsl:text>            if(rect.bottom &gt; bounds.bottom){
</xsl:text>
    <xsl:text>                let backup = first.getAttribute("dy");
</xsl:text>
    <xsl:text>                first.setAttribute("dy", "-"+String((this.lift+1)*1.1)+"em");
</xsl:text>
    <xsl:text>                rect = txt.getBoundingClientRect();
</xsl:text>
    <xsl:text>                if(rect.top &gt; bounds.top){
</xsl:text>
    <xsl:text>                    this.lift += 1;
</xsl:text>
    <xsl:text>                } else {
</xsl:text>
    <xsl:text>                    if(backup)
</xsl:text>
    <xsl:text>                        first.setAttribute("dy", backup);
</xsl:text>
    <xsl:text>                    else
</xsl:text>
    <xsl:text>                        first.removeAttribute("dy");
</xsl:text>
    <xsl:text>                    txt.removeChild(next);
</xsl:text>
    <xsl:text>                    return count;
</xsl:text>
    <xsl:text>                }
</xsl:text>
    <xsl:text>            }
</xsl:text>
    <xsl:text>            count++;
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>        return count;
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    inhibit_click_elsewhere: function(e) {
</xsl:text>
    <xsl:text>        console.log("inhibit", e);
</xsl:text>
    <xsl:text>        console.log(e.target.parentNode, this.text_elt);
</xsl:text>
    <xsl:text>        if(e.target.parentNode !== this.text_elt)
</xsl:text>
    <xsl:text>            e.stopPropagation();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    close: function(){
</xsl:text>
    <xsl:text>        this.reset_text();
</xsl:text>
    <xsl:text>        this.reset_box();
</xsl:text>
    <xsl:text>        this.element.appendChild(this.button_elt);
</xsl:text>
    <xsl:text>        this.apply_cache();
</xsl:text>
    <xsl:text>        document.removeEventListener("click", this.bound_inhibit_click_elsewhere, true);
</xsl:text>
    <xsl:text>        this.opened = false;
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    set_complete_text: function(){
</xsl:text>
    <xsl:text>        let spans = this.text_elt.children; 
</xsl:text>
    <xsl:text>        let c = 0;
</xsl:text>
    <xsl:text>        for(let item of this.content){
</xsl:text>
    <xsl:text>            let span=spans[c];
</xsl:text>
    <xsl:text>            span.textContent = item;
</xsl:text>
    <xsl:text>            span.setAttribute("onclick", "hmi_widgets['</xsl:text>
    <xsl:value-of select="$hmi_element/@id"/>
    <xsl:text>'].on_selection_click("+c+")");
</xsl:text>
    <xsl:text>            c++;
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    move: function(forward){
</xsl:text>
    <xsl:text>        let contentlength = this.content.length;
</xsl:text>
    <xsl:text>        let spans = this.text_elt.children; 
</xsl:text>
    <xsl:text>        let spanslength = spans.length;
</xsl:text>
    <xsl:text>        if(this.menu_offset != 0) spanslength--;
</xsl:text>
    <xsl:text>        if(this.menu_offset &lt; contentlength - 1) spanslength--;
</xsl:text>
    <xsl:text>        if(forward){
</xsl:text>
    <xsl:text>            this.menu_offset = Math.min(
</xsl:text>
    <xsl:text>                contentlength - spans.length + 1, 
</xsl:text>
    <xsl:text>                this.menu_offset + spanslength);
</xsl:text>
    <xsl:text>        }else{
</xsl:text>
    <xsl:text>            this.menu_offset = Math.max(
</xsl:text>
    <xsl:text>                0, 
</xsl:text>
    <xsl:text>                this.menu_offset - spanslength);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>        console.log(this.menu_offset);
</xsl:text>
    <xsl:text>        this.set_partial_text();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    set_partial_text: function(){
</xsl:text>
    <xsl:text>        let spans = this.text_elt.children; 
</xsl:text>
    <xsl:text>        let contentlength = this.content.length;
</xsl:text>
    <xsl:text>        let spanslength = spans.length;
</xsl:text>
    <xsl:text>        let i = this.menu_offset, c = 0;
</xsl:text>
    <xsl:text>        while(c &lt; spanslength){
</xsl:text>
    <xsl:text>            let span=spans[c];
</xsl:text>
    <xsl:text>            if(c == 0 &amp;&amp; i != 0){
</xsl:text>
    <xsl:text>                span.textContent = "&#x2191;  &#x2191;  &#x2191;";
</xsl:text>
    <xsl:text>                span.setAttribute("onclick", "hmi_widgets['</xsl:text>
    <xsl:value-of select="$hmi_element/@id"/>
    <xsl:text>'].on_backward_click()");
</xsl:text>
    <xsl:text>            }else if(c == spanslength-1 &amp;&amp; i &lt; contentlength - 1){
</xsl:text>
    <xsl:text>                span.textContent = "&#x2193;  &#x2193;  &#x2193;";
</xsl:text>
    <xsl:text>                span.setAttribute("onclick", "hmi_widgets['</xsl:text>
    <xsl:value-of select="$hmi_element/@id"/>
    <xsl:text>'].on_forward_click()");
</xsl:text>
    <xsl:text>            }else{
</xsl:text>
    <xsl:text>                span.textContent = this.content[i];
</xsl:text>
    <xsl:text>                span.setAttribute("onclick", "hmi_widgets['</xsl:text>
    <xsl:value-of select="$hmi_element/@id"/>
    <xsl:text>'].on_selection_click("+i+")");
</xsl:text>
    <xsl:text>                i++;
</xsl:text>
    <xsl:text>            }
</xsl:text>
    <xsl:text>            c++;
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    open: function(){
</xsl:text>
    <xsl:text>        let length = this.content.length;
</xsl:text>
    <xsl:text>        this.reset_text();
</xsl:text>
    <xsl:text>        let slots = this.grow_text(length);
</xsl:text>
    <xsl:text>        if(slots == length) {
</xsl:text>
    <xsl:text>            this.set_complete_text();
</xsl:text>
    <xsl:text>        } else {
</xsl:text>
    <xsl:text>            this.set_partial_text();
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>        this.adjust_box_to_text();
</xsl:text>
    <xsl:text>        this.element.removeChild(this.button_elt);
</xsl:text>
    <xsl:text>        this.element.parentNode.appendChild(this.element.parentNode.removeChild(this.element));
</xsl:text>
    <xsl:text>        // disable interaction with background
</xsl:text>
    <xsl:text>        document.addEventListener("click", this.bound_inhibit_click_elsewhere, true);
</xsl:text>
    <xsl:text>        this.opened = true;
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    reset_text: function(){
</xsl:text>
    <xsl:text>        let txt = this.text_elt; 
</xsl:text>
    <xsl:text>        let first = txt.firstElementChild;
</xsl:text>
    <xsl:text>        first.removeAttribute("onclick");
</xsl:text>
    <xsl:text>        first.removeAttribute("dy");
</xsl:text>
    <xsl:text>        for(let span of Array.from(txt.children).slice(1)){
</xsl:text>
    <xsl:text>            txt.removeChild(span)
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    reset_box: function(){
</xsl:text>
    <xsl:text>        let m = this.box_bbox;
</xsl:text>
    <xsl:text>        let b = this.box_elt;
</xsl:text>
    <xsl:text>        b.x.baseVal.value = m.x;
</xsl:text>
    <xsl:text>        b.y.baseVal.value = m.y;
</xsl:text>
    <xsl:text>        b.width.baseVal.value = m.width;
</xsl:text>
    <xsl:text>        b.height.baseVal.value = m.height;
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    adjust_box_to_text: function(){
</xsl:text>
    <xsl:text>        let [lmargin, tmargin] = this.margins;
</xsl:text>
    <xsl:text>        let m = this.text_elt.getBBox();
</xsl:text>
    <xsl:text>        let b = this.box_elt;
</xsl:text>
    <xsl:text>        b.x.baseVal.value = m.x - lmargin;
</xsl:text>
    <xsl:text>        b.y.baseVal.value = m.y - tmargin;
</xsl:text>
    <xsl:text>        b.width.baseVal.value = 2 * lmargin + m.width;
</xsl:text>
    <xsl:text>        b.height.baseVal.value = 2 * tmargin + m.height;
</xsl:text>
    <xsl:text>    },
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_defs" match="widget[@type='ForEach']">
    <xsl:param name="hmi_element"/>
    <xsl:variable name="widgets" select="func:refered_elements($forEach_widgets)[not(@id = $forEach_widgets_ids)]"/>
    <xsl:variable name="class" select="arg[1]/@value"/>
    <xsl:variable name="base_path" select="path/@value"/>
    <xsl:variable name="hmi_index_base" select="$indexed_hmitree/*[@hmipath = $base_path]"/>
    <xsl:variable name="hmi_tree_base" select="$hmitree/descendant-or-self::*[@path = $hmi_index_base/@path]"/>
    <xsl:variable name="hmi_tree_items" select="$hmi_tree_base/*[@class = $class]"/>
    <xsl:variable name="hmi_index_items" select="$indexed_hmitree/*[@path = $hmi_tree_items/@path]"/>
    <xsl:variable name="items_paths" select="$hmi_index_items/@hmipath"/>
    <xsl:text>    index_pool: [
</xsl:text>
    <xsl:for-each select="$hmi_index_items">
      <xsl:text>      </xsl:text>
      <xsl:value-of select="@index"/>
      <xsl:if test="position()!=last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>    ],
</xsl:text>
    <xsl:text>    init: function() {
</xsl:text>
    <xsl:variable name="prefix" select="concat($class,':')"/>
    <xsl:variable name="buttons_regex" select="concat('^',$prefix,'[+\-][0-9]+')"/>
    <xsl:variable name="buttons" select="$hmi_element/*[regexp:test(@inkscape:label, $buttons_regex)]"/>
    <xsl:for-each select="$buttons">
      <xsl:variable name="op" select="substring-after(@inkscape:label, $prefix)"/>
      <xsl:text>        id("</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>").setAttribute("onclick", "hmi_widgets['</xsl:text>
      <xsl:value-of select="$hmi_element/@id"/>
      <xsl:text>'].on_click('</xsl:text>
      <xsl:value-of select="$op"/>
      <xsl:text>', evt)");
</xsl:text>
    </xsl:for-each>
    <xsl:text>
</xsl:text>
    <xsl:text>        this.items = [
</xsl:text>
    <xsl:variable name="items_regex" select="concat('^',$prefix,'[0-9]+')"/>
    <xsl:variable name="unordered_items" select="$hmi_element//*[regexp:test(@inkscape:label, $items_regex)]"/>
    <xsl:for-each select="$unordered_items">
      <xsl:variable name="elt_label" select="concat($prefix, string(position()))"/>
      <xsl:variable name="elt" select="$unordered_items[@inkscape:label = $elt_label]"/>
      <xsl:variable name="pos" select="position()"/>
      <xsl:variable name="item_path" select="$items_paths[$pos]"/>
      <xsl:text>          [ /* item="</xsl:text>
      <xsl:value-of select="$elt_label"/>
      <xsl:text>" path="</xsl:text>
      <xsl:value-of select="$item_path"/>
      <xsl:text>" */
</xsl:text>
      <xsl:if test="count($elt)=0">
        <xsl:message terminate="yes">
          <xsl:text>Missing item labeled </xsl:text>
          <xsl:value-of select="$elt_label"/>
          <xsl:text> in ForEach widget </xsl:text>
          <xsl:value-of select="$hmi_element/@id"/>
        </xsl:message>
      </xsl:if>
      <xsl:for-each select="func:refered_elements($elt)[@id = $hmi_elements/@id][not(@id = $elt/@id)]">
        <xsl:if test="not(func:is_descendant_path(func:widget(@id)/path/@value, $item_path))">
          <xsl:message terminate="yes">
            <xsl:text>Widget id="</xsl:text>
            <xsl:value-of select="@id"/>
            <xsl:text>" label="</xsl:text>
            <xsl:value-of select="@inkscape:label"/>
            <xsl:text>" is having wrong path. Accroding to ForEach widget ancestor id="</xsl:text>
            <xsl:value-of select="$hmi_element/@id"/>
            <xsl:text>", path should be descendant of "</xsl:text>
            <xsl:value-of select="$item_path"/>
            <xsl:text>".</xsl:text>
          </xsl:message>
        </xsl:if>
        <xsl:text>            hmi_widgets["</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text>"]</xsl:text>
        <xsl:if test="position()!=last()">
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:text>
</xsl:text>
      </xsl:for-each>
      <xsl:text>          ]</xsl:text>
      <xsl:if test="position()!=last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>        ]
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    item_offset: 0,
</xsl:text>
    <xsl:text>    on_click: foreach_onclick,
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_subscribe" match="widget[@type='ForEach']">
    <xsl:text>    sub: foreach_subscribe,
</xsl:text>
    <xsl:text>    unsub: foreach_unsubscribe,
</xsl:text>
    <xsl:text>    apply_cache: foreach_apply_cache,
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_defs" match="widget[@type='Input']">
    <xsl:param name="hmi_element"/>
    <xsl:variable name="value_elt">
      <xsl:call-template name="defs_by_labels">
        <xsl:with-param name="hmi_element" select="$hmi_element"/>
        <xsl:with-param name="labels">
          <xsl:text>value</xsl:text>
        </xsl:with-param>
        <xsl:with-param name="mandatory" select="'no'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="have_value" select="string-length($value_elt)&gt;0"/>
    <xsl:value-of select="$value_elt"/>
    <xsl:if test="$have_value">
      <xsl:text>    frequency: 5,
</xsl:text>
    </xsl:if>
    <xsl:text>    last_val: undefined,
</xsl:text>
    <xsl:text>    dispatch: function(value) {
</xsl:text>
    <xsl:text>        this.last_val = value;
</xsl:text>
    <xsl:if test="$have_value">
      <xsl:text>        this.value_elt.textContent = String(value);
</xsl:text>
    </xsl:if>
    <xsl:text>    },
</xsl:text>
    <xsl:variable name="edit_elt_id" select="$hmi_element/*[@inkscape:label='edit'][1]/@id"/>
    <xsl:text>    init: function() {
</xsl:text>
    <xsl:if test="$edit_elt_id">
      <xsl:text>        id("</xsl:text>
      <xsl:value-of select="$edit_elt_id"/>
      <xsl:text>").setAttribute("onclick", "hmi_widgets['</xsl:text>
      <xsl:value-of select="$hmi_element/@id"/>
      <xsl:text>'].on_edit_click()");
</xsl:text>
    </xsl:if>
    <xsl:for-each select="$hmi_element/*[regexp:test(@inkscape:label,'^[=+\-].+')]">
      <xsl:text>        id("</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>").setAttribute("onclick", "hmi_widgets['</xsl:text>
      <xsl:value-of select="$hmi_element/@id"/>
      <xsl:text>'].on_op_click('</xsl:text>
      <xsl:value-of select="func:escape_quotes(@inkscape:label)"/>
      <xsl:text>')");
</xsl:text>
    </xsl:for-each>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_op_click: function(opstr) {
</xsl:text>
    <xsl:text>        let orig = this.indexes[0];
</xsl:text>
    <xsl:text>        let idx = this.offset ? orig - this.offset : orig;
</xsl:text>
    <xsl:text>        let new_val = change_hmi_value(idx, opstr);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_edit_click: function(opstr) {
</xsl:text>
    <xsl:text>        edit_value("</xsl:text>
    <xsl:value-of select="path/@value"/>
    <xsl:text>", "</xsl:text>
    <xsl:value-of select="path/@type"/>
    <xsl:text>", this, this.last_val);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    edit_callback: function(new_val) {
</xsl:text>
    <xsl:text>        let orig = this.indexes[0];
</xsl:text>
    <xsl:text>        let idx = this.offset ? orig - this.offset : orig;
</xsl:text>
    <xsl:text>        apply_hmi_value(idx, new_val);
</xsl:text>
    <xsl:text>    },
</xsl:text>
  </xsl:template>
  <xsl:template name="jump_widget_activity">
    <xsl:param name="hmi_element"/>
    <xsl:call-template name="defs_by_labels">
      <xsl:with-param name="hmi_element" select="$hmi_element"/>
      <xsl:with-param name="labels">
        <xsl:text>active inactive</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="mandatory" select="'no'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="jump_widget_disability">
    <xsl:param name="hmi_element"/>
    <xsl:call-template name="defs_by_labels">
      <xsl:with-param name="hmi_element" select="$hmi_element"/>
      <xsl:with-param name="labels">
        <xsl:text>disabled</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="mandatory" select="'no'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template mode="widget_defs" match="widget[@type='Jump']">
    <xsl:param name="hmi_element"/>
    <xsl:variable name="activity">
      <xsl:call-template name="jump_widget_activity">
        <xsl:with-param name="hmi_element" select="$hmi_element"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="have_activity" select="string-length($activity)&gt;0"/>
    <xsl:value-of select="$activity"/>
    <xsl:variable name="disability">
      <xsl:call-template name="jump_widget_disability">
        <xsl:with-param name="hmi_element" select="$hmi_element"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="have_disability" select="$have_activity and string-length($disability)&gt;0"/>
    <xsl:value-of select="$disability"/>
    <xsl:if test="$have_activity">
      <xsl:text>    active: false,
</xsl:text>
      <xsl:if test="$have_disability">
        <xsl:text>    disabled: false,
</xsl:text>
        <xsl:text>    frequency: 2,
</xsl:text>
        <xsl:text>    dispatch: function(value) {
</xsl:text>
        <xsl:text>        this.disabled = !Number(value);
</xsl:text>
        <xsl:text>        this.update();
</xsl:text>
        <xsl:text>    },
</xsl:text>
      </xsl:if>
      <xsl:text>    update: function(){
</xsl:text>
      <xsl:if test="$have_disability">
        <xsl:text>      if(this.disabled) {
</xsl:text>
        <xsl:text>        /* show disabled */ 
</xsl:text>
        <xsl:text>        this.disabled_elt.setAttribute("style", this.active_elt_style);
</xsl:text>
        <xsl:text>        /* hide inactive */ 
</xsl:text>
        <xsl:text>        this.inactive_elt.setAttribute("style", "display:none");
</xsl:text>
        <xsl:text>        /* hide active */ 
</xsl:text>
        <xsl:text>        this.active_elt.setAttribute("style", "display:none");
</xsl:text>
        <xsl:text>      } else {
</xsl:text>
        <xsl:text>        /* hide disabled */ 
</xsl:text>
        <xsl:text>        this.disabled_elt.setAttribute("style", "display:none");
</xsl:text>
      </xsl:if>
      <xsl:text>        if(this.active) {
</xsl:text>
      <xsl:text>             /* show active */ 
</xsl:text>
      <xsl:text>             this.active_elt.setAttribute("style", this.active_elt_style);
</xsl:text>
      <xsl:text>             /* hide inactive */ 
</xsl:text>
      <xsl:text>             this.inactive_elt.setAttribute("style", "display:none");
</xsl:text>
      <xsl:text>        } else {
</xsl:text>
      <xsl:text>             /* show inactive */ 
</xsl:text>
      <xsl:text>             this.inactive_elt.setAttribute("style", this.inactive_elt_style);
</xsl:text>
      <xsl:text>             /* hide active */ 
</xsl:text>
      <xsl:text>             this.active_elt.setAttribute("style", "display:none");
</xsl:text>
      <xsl:text>        }
</xsl:text>
      <xsl:if test="$have_disability">
        <xsl:text>      }
</xsl:text>
      </xsl:if>
      <xsl:text>    },
</xsl:text>
    </xsl:if>
    <xsl:text>    on_click: function(evt) {
</xsl:text>
    <xsl:text>        const index = this.indexes.length &gt; 0 ? this.indexes[0] + this.offset : undefined;
</xsl:text>
    <xsl:text>        const name = this.args[0];
</xsl:text>
    <xsl:text>        switch_page(name, index);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:if test="$have_activity">
      <xsl:text>    notify_page_change: function(page_name, index){
</xsl:text>
      <xsl:text>        const ref_index = this.indexes.length &gt; 0 ? this.indexes[0] + this.offset : undefined;
</xsl:text>
      <xsl:text>        const ref_name = this.args[0];
</xsl:text>
      <xsl:text>        this.active =((ref_name == undefined || ref_name == page_name) &amp;&amp; index == ref_index);
</xsl:text>
      <xsl:text>        this.update();
</xsl:text>
      <xsl:text>    },
</xsl:text>
    </xsl:if>
    <xsl:text>    init: function() {
</xsl:text>
    <xsl:text>        this.element.setAttribute("onclick", "hmi_widgets['</xsl:text>
    <xsl:value-of select="$hmi_element/@id"/>
    <xsl:text>'].on_click(evt)");
</xsl:text>
    <xsl:if test="$have_activity">
      <xsl:text>        this.active_elt_style = this.active_elt.getAttribute("style");
</xsl:text>
      <xsl:text>        this.inactive_elt_style = this.inactive_elt.getAttribute("style");
</xsl:text>
    </xsl:if>
    <xsl:if test="$have_disability">
      <xsl:text>        this.disabled_elt_style = this.disabled_elt.getAttribute("style");
</xsl:text>
    </xsl:if>
    <xsl:text>    },
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_subscribe" match="widget[@type='Jump']">
    <xsl:param name="hmi_element"/>
    <xsl:variable name="activity">
      <xsl:call-template name="jump_widget_activity">
        <xsl:with-param name="hmi_element" select="$hmi_element"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="have_activity" select="string-length($activity)&gt;0"/>
    <xsl:variable name="disability">
      <xsl:call-template name="jump_widget_disability">
        <xsl:with-param name="hmi_element" select="$hmi_element"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="have_disability" select="$have_activity and string-length($disability)&gt;0"/>
    <xsl:choose>
      <xsl:when test="$have_disability">
        <xsl:text>    sub: subscribe,
</xsl:text>
        <xsl:text>    unsub: unsubscribe,
</xsl:text>
        <xsl:text>    apply_cache: widget_apply_cache,
</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>    sub: function(){},
</xsl:text>
        <xsl:text>    unsub: function(){},
</xsl:text>
        <xsl:text>    apply_cache: function(){},
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template mode="per_page_widget_template" match="widget[@type='Jump']">
    <xsl:param name="page_desc"/>
    <xsl:if test="path">
      <xsl:variable name="target_page_name">
        <xsl:choose>
          <xsl:when test="arg">
            <xsl:value-of select="arg[1]/@value"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$page_desc/arg[1]/@value"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="target_page_path">
        <xsl:choose>
          <xsl:when test="arg">
            <xsl:value-of select="$hmi_pages_descs[arg[1]/@value = $target_page_name]/path[1]/@value"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$page_desc/path[1]/@value"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:if test="not(func:same_class_paths($target_page_path, path[1]/@value))">
        <xsl:message terminate="yes">
          <xsl:text>Jump id="</xsl:text>
          <xsl:value-of select="@id"/>
          <xsl:text>" to page "</xsl:text>
          <xsl:value-of select="$target_page_name"/>
          <xsl:text>" with incompatible path "</xsl:text>
          <xsl:value-of select="path[1]/@value"/>
          <xsl:text> (must be same class as "</xsl:text>
          <xsl:value-of select="$target_page_path"/>
          <xsl:text>")</xsl:text>
        </xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  <xsl:template mode="widget_defs" match="widget[@type='Keypad']">
    <xsl:param name="hmi_element"/>
    <xsl:call-template name="defs_by_labels">
      <xsl:with-param name="hmi_element" select="$hmi_element"/>
      <xsl:with-param name="labels">
        <xsl:text>Esc Enter BackSpace Keys Info Value</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="defs_by_labels">
      <xsl:with-param name="hmi_element" select="$hmi_element"/>
      <xsl:with-param name="labels">
        <xsl:text>Sign Space NumDot</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="mandatory" select="'no'"/>
    </xsl:call-template>
    <xsl:call-template name="defs_by_labels">
      <xsl:with-param name="hmi_element" select="$hmi_element"/>
      <xsl:with-param name="labels">
        <xsl:text>CapsLock Shift</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="mandatory" select="'no'"/>
      <xsl:with-param name="subelements" select="'active inactive'"/>
    </xsl:call-template>
    <xsl:text>    init: function() {
</xsl:text>
    <xsl:for-each select="$hmi_element/*[@inkscape:label = 'Keys']/*">
      <xsl:text>        id("</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>").setAttribute("onclick", "hmi_widgets['</xsl:text>
      <xsl:value-of select="$hmi_element/@id"/>
      <xsl:text>'].on_key_click('</xsl:text>
      <xsl:value-of select="func:escape_quotes(@inkscape:label)"/>
      <xsl:text>')");
</xsl:text>
    </xsl:for-each>
    <xsl:for-each select="str:split('Esc Enter BackSpace Sign Space NumDot CapsLock Shift')">
      <xsl:text>        if(this.</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>_elt)
</xsl:text>
      <xsl:text>            this.</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>_elt.setAttribute("onclick", "hmi_widgets['</xsl:text>
      <xsl:value-of select="$hmi_element/@id"/>
      <xsl:text>'].on_</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>_click()");
</xsl:text>
    </xsl:for-each>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_key_click: function(symbols) {
</xsl:text>
    <xsl:text>        var syms = symbols.split(" ");
</xsl:text>
    <xsl:text>        this.shift |= this.caps;
</xsl:text>
    <xsl:text>        this.editstr += syms[this.shift?syms.length-1:0];
</xsl:text>
    <xsl:text>        this.shift = false;
</xsl:text>
    <xsl:text>        this.update();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_Esc_click: function() {
</xsl:text>
    <xsl:text>        end_modal.call(this);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_Enter_click: function() {
</xsl:text>
    <xsl:text>        end_modal.call(this);
</xsl:text>
    <xsl:text>        callback_obj = this.result_callback_obj;
</xsl:text>
    <xsl:text>        callback_obj.edit_callback(this.editstr);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_BackSpace_click: function() {
</xsl:text>
    <xsl:text>        this.editstr = this.editstr.slice(0,this.editstr.length-1);
</xsl:text>
    <xsl:text>        this.update();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_Sign_click: function() {
</xsl:text>
    <xsl:text>        if(this.editstr[0] == "-")
</xsl:text>
    <xsl:text>            this.editstr = this.editstr.slice(1,this.editstr.length);
</xsl:text>
    <xsl:text>        else
</xsl:text>
    <xsl:text>            this.editstr = "-" + this.editstr;
</xsl:text>
    <xsl:text>        this.update();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_NumDot_click: function() {
</xsl:text>
    <xsl:text>        if(this.editstr.indexOf(".") == "-1"){
</xsl:text>
    <xsl:text>            this.editstr += ".";
</xsl:text>
    <xsl:text>            this.update();
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    on_Space_click: function() {
</xsl:text>
    <xsl:text>        this.editstr += " ";
</xsl:text>
    <xsl:text>        this.update();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    caps: false,
</xsl:text>
    <xsl:text>    _caps: undefined,
</xsl:text>
    <xsl:text>    on_CapsLock_click: function() {
</xsl:text>
    <xsl:text>        this.caps = !this.caps;
</xsl:text>
    <xsl:text>        this.update();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    shift: false,
</xsl:text>
    <xsl:text>    _shift: undefined,
</xsl:text>
    <xsl:text>    on_Shift_click: function() {
</xsl:text>
    <xsl:text>        this.shift = !this.shift;
</xsl:text>
    <xsl:text>        this.caps = false;
</xsl:text>
    <xsl:text>        this.update();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:variable name="g" select="$geometry[@Id = $hmi_element/@id]"/>
    <xsl:text>    coordinates: [</xsl:text>
    <xsl:value-of select="$g/@x"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="$g/@y"/>
    <xsl:text>],
</xsl:text>
    <xsl:text>    editstr: "",
</xsl:text>
    <xsl:text>    _editstr: undefined,
</xsl:text>
    <xsl:text>    result_callback_obj: undefined,
</xsl:text>
    <xsl:text>    start_edit: function(info, valuetype, callback_obj, initial) {
</xsl:text>
    <xsl:text>        show_modal.call(this);
</xsl:text>
    <xsl:text>        this.editstr = initial;
</xsl:text>
    <xsl:text>        this.result_callback_obj = callback_obj;
</xsl:text>
    <xsl:text>        this.Info_elt.textContent = info;
</xsl:text>
    <xsl:text>        this.shift = false;
</xsl:text>
    <xsl:text>        this.caps = false;
</xsl:text>
    <xsl:text>        this.update();
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    update: function() {
</xsl:text>
    <xsl:text>        if(this.editstr != this._editstr){
</xsl:text>
    <xsl:text>            this._editstr = this.editstr;
</xsl:text>
    <xsl:text>            this.Value_elt.textContent = this.editstr;
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>        if(this.shift != this._shift){
</xsl:text>
    <xsl:text>            this._shift = this.shift;
</xsl:text>
    <xsl:text>            (this.shift?widget_active_activable:widget_inactive_activable)(this.Shift_sub);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>        if(this.caps != this._caps){
</xsl:text>
    <xsl:text>            this._caps = this.caps;
</xsl:text>
    <xsl:text>            (this.caps?widget_active_activable:widget_inactive_activable)(this.CapsLock_sub);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    },
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_defs" match="widget[@type='Meter']">
    <xsl:param name="hmi_element"/>
    <xsl:text>    frequency: 10,
</xsl:text>
    <xsl:call-template name="defs_by_labels">
      <xsl:with-param name="hmi_element" select="$hmi_element"/>
      <xsl:with-param name="labels">
        <xsl:text>needle range</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="defs_by_labels">
      <xsl:with-param name="hmi_element" select="$hmi_element"/>
      <xsl:with-param name="labels">
        <xsl:text>value min max</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="mandatory" select="'no'"/>
    </xsl:call-template>
    <xsl:text>    dispatch: function(value) {
</xsl:text>
    <xsl:text>        if(this.value_elt)
</xsl:text>
    <xsl:text>            this.value_elt.textContent = String(value);
</xsl:text>
    <xsl:text>        let [min,max,totallength] = this.range;
</xsl:text>
    <xsl:text>        let length = Math.max(0,Math.min(totallength,(Number(value)-min)*totallength/(max-min)));
</xsl:text>
    <xsl:text>        let tip = this.range_elt.getPointAtLength(length);
</xsl:text>
    <xsl:text>        this.needle_elt.setAttribute('d', "M "+this.origin.x+","+this.origin.y+" "+tip.x+","+tip.y);
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    origin: undefined,
</xsl:text>
    <xsl:text>    range: undefined,
</xsl:text>
    <xsl:text>    init: function() {
</xsl:text>
    <xsl:text>        let min = this.min_elt ?
</xsl:text>
    <xsl:text>                    Number(this.min_elt.textContent) :
</xsl:text>
    <xsl:text>                    this.args.length &gt;= 1 ? this.args[0] : 0;
</xsl:text>
    <xsl:text>        let max = this.max_elt ?
</xsl:text>
    <xsl:text>                    Number(this.max_elt.textContent) :
</xsl:text>
    <xsl:text>                    this.args.length &gt;= 2 ? this.args[1] : 100;
</xsl:text>
    <xsl:text>        this.range = [min, max, this.range_elt.getTotalLength()]
</xsl:text>
    <xsl:text>        this.origin = this.needle_elt.getPointAtLength(0);
</xsl:text>
    <xsl:text>    },
</xsl:text>
  </xsl:template>
  <xsl:template mode="widget_defs" match="widget[@type='Switch']">
    <xsl:param name="hmi_element"/>
    <xsl:text>    frequency: 5,
</xsl:text>
    <xsl:text>    dispatch: function(value) {
</xsl:text>
    <xsl:text>        for(let choice of this.choices){
</xsl:text>
    <xsl:text>            if(value != choice.value){
</xsl:text>
    <xsl:text>                choice.elt.setAttribute("style", "display:none");
</xsl:text>
    <xsl:text>            } else {
</xsl:text>
    <xsl:text>                choice.elt.setAttribute("style", choice.style);
</xsl:text>
    <xsl:text>            }
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    init: function() {
</xsl:text>
    <xsl:text>        // Hello Switch
</xsl:text>
    <xsl:text>    },
</xsl:text>
    <xsl:text>    choices: [
</xsl:text>
    <xsl:variable name="regex" select="'^(&quot;[^&quot;].*&quot;|\-?[0-9]+|false|true)(#.*)?$'"/>
    <xsl:for-each select="$hmi_element/*[regexp:test(@inkscape:label,$regex)]">
      <xsl:variable name="literal" select="regexp:match(@inkscape:label,$regex)[2]"/>
      <xsl:text>        {
</xsl:text>
      <xsl:text>            elt:id("</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>"),
</xsl:text>
      <xsl:text>            style:"</xsl:text>
      <xsl:value-of select="@style"/>
      <xsl:text>",
</xsl:text>
      <xsl:text>            value:</xsl:text>
      <xsl:value-of select="$literal"/>
      <xsl:text>
</xsl:text>
      <xsl:text>        }</xsl:text>
      <xsl:if test="position()!=last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>    ],
</xsl:text>
  </xsl:template>
  <xsl:template mode="debug_as_comment" match="*[namespace-uri()='reflect']">
    <xsl:comment>
      <xsl:value-of select="local-name()"/>
      <xsl:text> :
</xsl:text>
      <xsl:apply-templates mode="debug" select="."/>
    </xsl:comment>
  </xsl:template>
  <xsl:template match="/">
    <xsl:comment>
      <xsl:text>Made with SVGHMI. https://beremiz.org</xsl:text>
    </xsl:comment>
    <html xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/1999/xhtml">
      <head/>
      <body style="margin:0;overflow:hidden;">
        <xsl:copy-of select="$result_svg"/>
        <script>
          <xsl:call-template name="scripts"/>
        </script>
      </body>
    </html>
  </xsl:template>
  <xsl:template name="scripts">
    <xsl:text>
</xsl:text>
    <xsl:text>id = idstr =&gt; document.getElementById(idstr);
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var hmi_hash = [</xsl:text>
    <xsl:value-of select="$hmitree/@hash"/>
    <xsl:text>]; 
</xsl:text>
    <xsl:text>var hmi_widgets = {
</xsl:text>
    <xsl:apply-templates mode="hmi_elements" select="$hmi_elements"/>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var heartbeat_index = </xsl:text>
    <xsl:value-of select="$indexed_hmitree/*[@hmipath = '/HEARTBEAT']/@index"/>
    <xsl:text>;
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var hmitree_types = [
</xsl:text>
    <xsl:for-each select="$indexed_hmitree/*">
      <xsl:text>    /* </xsl:text>
      <xsl:value-of select="@index"/>
      <xsl:text>  </xsl:text>
      <xsl:value-of select="@hmipath"/>
      <xsl:text> */ "</xsl:text>
      <xsl:value-of select="substring(local-name(), 5)"/>
      <xsl:text>"</xsl:text>
      <xsl:if test="position()!=last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>]
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var detachable_elements = {
</xsl:text>
    <xsl:for-each select="$detachable_elements">
      <xsl:text>    "</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>":[id("</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>"), id("</xsl:text>
      <xsl:value-of select="../@id"/>
      <xsl:text>")]</xsl:text>
      <xsl:if test="position()!=last()">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var page_desc = {
</xsl:text>
    <xsl:apply-templates mode="page_desc" select="$hmi_pages"/>
    <xsl:text>}
</xsl:text>
    <xsl:text>var keypads = {
</xsl:text>
    <xsl:for-each select="$keypads_descs">
      <xsl:variable name="keypad_id" select="@id"/>
      <xsl:for-each select="arg">
        <xsl:variable name="g" select="$geometry[@Id = $keypad_id]"/>
        <xsl:text>    "</xsl:text>
        <xsl:value-of select="@value"/>
        <xsl:text>":["</xsl:text>
        <xsl:value-of select="$keypad_id"/>
        <xsl:text>", </xsl:text>
        <xsl:value-of select="$g/@x"/>
        <xsl:text>, </xsl:text>
        <xsl:value-of select="$g/@y"/>
        <xsl:text>],
</xsl:text>
      </xsl:for-each>
    </xsl:for-each>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var default_page = "</xsl:text>
    <xsl:value-of select="$default_page"/>
    <xsl:text>";
</xsl:text>
    <xsl:text>var svg_root = id("</xsl:text>
    <xsl:value-of select="/svg:svg/@id"/>
    <xsl:text>");
</xsl:text>
    <xsl:text>// svghmi.js
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var cache = hmitree_types.map(_ignored =&gt; undefined);
</xsl:text>
    <xsl:text>var updates = {};
</xsl:text>
    <xsl:text>var need_cache_apply = []; 
</xsl:text>
    <xsl:text>var jumps_need_update = false;
</xsl:text>
    <xsl:text>var jump_history = [[default_page, undefined]];
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function dispatch_value_to_widget(widget, index, value, oldval) {
</xsl:text>
    <xsl:text>    try {
</xsl:text>
    <xsl:text>        let idx = widget.offset ? index - widget.offset : index;
</xsl:text>
    <xsl:text>        let idxidx = widget.indexes.indexOf(idx);
</xsl:text>
    <xsl:text>        let d = widget.dispatch;
</xsl:text>
    <xsl:text>        if(typeof(d) == "function" &amp;&amp; idxidx == 0){
</xsl:text>
    <xsl:text>            d.call(widget, value, oldval);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>        else if(typeof(d) == "object" &amp;&amp; d.length &gt;= idxidx){
</xsl:text>
    <xsl:text>            d[idxidx].call(widget, value, oldval);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>        /* else dispatch_0, ..., dispatch_n ? */
</xsl:text>
    <xsl:text>        /*else {
</xsl:text>
    <xsl:text>            throw new Error("Dunno how to dispatch to widget at index = " + index);
</xsl:text>
    <xsl:text>        }*/
</xsl:text>
    <xsl:text>    } catch(err) {
</xsl:text>
    <xsl:text>        console.log(err);
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function dispatch_value(index, value) {
</xsl:text>
    <xsl:text>    let widgets = subscribers[index];
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    let oldval = cache[index];
</xsl:text>
    <xsl:text>    cache[index] = value;
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    if(widgets.size &gt; 0) {
</xsl:text>
    <xsl:text>        for(let widget of widgets){
</xsl:text>
    <xsl:text>            dispatch_value_to_widget(widget, index, value, oldval);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function init_widgets() {
</xsl:text>
    <xsl:text>    Object.keys(hmi_widgets).forEach(function(id) {
</xsl:text>
    <xsl:text>        let widget = hmi_widgets[id];
</xsl:text>
    <xsl:text>        let init = widget.init;
</xsl:text>
    <xsl:text>        if(typeof(init) == "function"){
</xsl:text>
    <xsl:text>            try {
</xsl:text>
    <xsl:text>                init.call(widget);
</xsl:text>
    <xsl:text>            } catch(err) {
</xsl:text>
    <xsl:text>                console.log(err);
</xsl:text>
    <xsl:text>            }
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    });
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>// Open WebSocket to relative "/ws" address
</xsl:text>
    <xsl:text>var ws = new WebSocket(window.location.href.replace(/^http(s?:\/\/[^\/]*)\/.*$/, 'ws$1/ws'));
</xsl:text>
    <xsl:text>ws.binaryType = 'arraybuffer';
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>const dvgetters = {
</xsl:text>
    <xsl:text>    INT: (dv,offset) =&gt; [dv.getInt16(offset, true), 2],
</xsl:text>
    <xsl:text>    BOOL: (dv,offset) =&gt; [dv.getInt8(offset, true), 1],
</xsl:text>
    <xsl:text>    NODE: (dv,offset) =&gt; [dv.getInt8(offset, true), 1],
</xsl:text>
    <xsl:text>    STRING: (dv, offset) =&gt; {
</xsl:text>
    <xsl:text>        size = dv.getInt8(offset);
</xsl:text>
    <xsl:text>        return [
</xsl:text>
    <xsl:text>            String.fromCharCode.apply(null, new Uint8Array(
</xsl:text>
    <xsl:text>                dv.buffer, /* original buffer */
</xsl:text>
    <xsl:text>                offset + 1, /* string starts after size*/
</xsl:text>
    <xsl:text>                size /* size of string */
</xsl:text>
    <xsl:text>            )), size + 1]; /* total increment */
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>// Apply updates recieved through ws.onmessage to subscribed widgets
</xsl:text>
    <xsl:text>function apply_updates() {
</xsl:text>
    <xsl:text>    for(let index in updates){
</xsl:text>
    <xsl:text>        // serving as a key, index becomes a string
</xsl:text>
    <xsl:text>        // -&gt; pass Number(index) instead
</xsl:text>
    <xsl:text>        dispatch_value(Number(index), updates[index]);
</xsl:text>
    <xsl:text>        delete updates[index];
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>// Called on requestAnimationFrame, modifies DOM
</xsl:text>
    <xsl:text>var requestAnimationFrameID = null;
</xsl:text>
    <xsl:text>function animate() {
</xsl:text>
    <xsl:text>    // Do the page swith if any one pending
</xsl:text>
    <xsl:text>    if(current_subscribed_page != current_visible_page){
</xsl:text>
    <xsl:text>        switch_visible_page(current_subscribed_page);
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    while(widget = need_cache_apply.pop()){
</xsl:text>
    <xsl:text>        widget.apply_cache();
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    if(jumps_need_update) update_jumps();
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    apply_updates();
</xsl:text>
    <xsl:text>    requestAnimationFrameID = null;
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function requestHMIAnimation() {
</xsl:text>
    <xsl:text>    if(requestAnimationFrameID == null){
</xsl:text>
    <xsl:text>        requestAnimationFrameID = window.requestAnimationFrame(animate);
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>// Message reception handler
</xsl:text>
    <xsl:text>// Hash is verified and HMI values updates resulting from binary parsing
</xsl:text>
    <xsl:text>// are stored until browser can compute next frame, DOM is left untouched
</xsl:text>
    <xsl:text>ws.onmessage = function (evt) {
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    let data = evt.data;
</xsl:text>
    <xsl:text>    let dv = new DataView(data);
</xsl:text>
    <xsl:text>    let i = 0;
</xsl:text>
    <xsl:text>    try {
</xsl:text>
    <xsl:text>        for(let hash_int of hmi_hash) {
</xsl:text>
    <xsl:text>            if(hash_int != dv.getUint8(i)){
</xsl:text>
    <xsl:text>                throw new Error("Hash doesn't match");
</xsl:text>
    <xsl:text>            };
</xsl:text>
    <xsl:text>            i++;
</xsl:text>
    <xsl:text>        };
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>        while(i &lt; data.byteLength){
</xsl:text>
    <xsl:text>            let index = dv.getUint32(i, true);
</xsl:text>
    <xsl:text>            i += 4;
</xsl:text>
    <xsl:text>            let iectype = hmitree_types[index];
</xsl:text>
    <xsl:text>            if(iectype != undefined){
</xsl:text>
    <xsl:text>                let dvgetter = dvgetters[iectype];
</xsl:text>
    <xsl:text>                let [value, bytesize] = dvgetter(dv,i);
</xsl:text>
    <xsl:text>                updates[index] = value;
</xsl:text>
    <xsl:text>                i += bytesize;
</xsl:text>
    <xsl:text>            } else {
</xsl:text>
    <xsl:text>                throw new Error("Unknown index "+index);
</xsl:text>
    <xsl:text>            }
</xsl:text>
    <xsl:text>        };
</xsl:text>
    <xsl:text>        // register for rendering on next frame, since there are updates
</xsl:text>
    <xsl:text>        requestHMIAnimation();
</xsl:text>
    <xsl:text>    } catch(err) {
</xsl:text>
    <xsl:text>        // 1003 is for "Unsupported Data"
</xsl:text>
    <xsl:text>        // ws.close(1003, err.message);
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>        // TODO : remove debug alert ?
</xsl:text>
    <xsl:text>        alert("Error : "+err.message+"\nHMI will be reloaded.");
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>        // force reload ignoring cache
</xsl:text>
    <xsl:text>        location.reload(true);
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function send_blob(data) {
</xsl:text>
    <xsl:text>    if(data.length &gt; 0) {
</xsl:text>
    <xsl:text>        ws.send(new Blob([new Uint8Array(hmi_hash)].concat(data)));
</xsl:text>
    <xsl:text>    };
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>const typedarray_types = {
</xsl:text>
    <xsl:text>    INT: (number) =&gt; new Int16Array([number]),
</xsl:text>
    <xsl:text>    BOOL: (truth) =&gt; new Int16Array([truth]),
</xsl:text>
    <xsl:text>    NODE: (truth) =&gt; new Int16Array([truth]),
</xsl:text>
    <xsl:text>    STRING: (str) =&gt; {
</xsl:text>
    <xsl:text>        // beremiz default string max size is 128
</xsl:text>
    <xsl:text>        str = str.slice(0,128);
</xsl:text>
    <xsl:text>        binary = new Uint8Array(str.length + 1);
</xsl:text>
    <xsl:text>        binary[0] = str.length;
</xsl:text>
    <xsl:text>        for(var i = 0; i &lt; str.length; i++){
</xsl:text>
    <xsl:text>            binary[i+1] = str.charCodeAt(i);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>        return binary;
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>    /* TODO */
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function send_reset() {
</xsl:text>
    <xsl:text>    send_blob(new Uint8Array([1])); /* reset = 1 */
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>// subscription state, as it should be in hmi server
</xsl:text>
    <xsl:text>// hmitree indexed array of integers
</xsl:text>
    <xsl:text>var subscriptions =  hmitree_types.map(_ignored =&gt; 0);
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>// subscription state as needed by widget now
</xsl:text>
    <xsl:text>// hmitree indexed array of Sets of widgets objects
</xsl:text>
    <xsl:text>var subscribers = hmitree_types.map(_ignored =&gt; new Set());
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>// artificially subscribe the watchdog widget to "/heartbeat" hmi variable
</xsl:text>
    <xsl:text>// Since dispatch directly calls change_hmi_value,
</xsl:text>
    <xsl:text>// PLC will periodically send variable at given frequency
</xsl:text>
    <xsl:text>subscribers[heartbeat_index].add({
</xsl:text>
    <xsl:text>    /* type: "Watchdog", */
</xsl:text>
    <xsl:text>    frequency: 1,
</xsl:text>
    <xsl:text>    indexes: [heartbeat_index],
</xsl:text>
    <xsl:text>    dispatch: function(value) {
</xsl:text>
    <xsl:text>        change_hmi_value(heartbeat_index, "+1");
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>});
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function update_subscriptions() {
</xsl:text>
    <xsl:text>    let delta = [];
</xsl:text>
    <xsl:text>    for(let index = 0; index &lt; subscribers.length; index++){
</xsl:text>
    <xsl:text>        let widgets = subscribers[index];
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>        // periods are in ms
</xsl:text>
    <xsl:text>        let previous_period = subscriptions[index];
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>        // subscribing with a zero period is unsubscribing
</xsl:text>
    <xsl:text>        let new_period = 0;
</xsl:text>
    <xsl:text>        if(widgets.size &gt; 0) {
</xsl:text>
    <xsl:text>            let maxfreq = 0;
</xsl:text>
    <xsl:text>            for(let widget of widgets)
</xsl:text>
    <xsl:text>                if(maxfreq &lt; widget.frequency)
</xsl:text>
    <xsl:text>                    maxfreq = widget.frequency;
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>            if(maxfreq != 0)
</xsl:text>
    <xsl:text>                new_period = 1000/maxfreq;
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>        if(previous_period != new_period) {
</xsl:text>
    <xsl:text>            subscriptions[index] = new_period;
</xsl:text>
    <xsl:text>            delta.push(
</xsl:text>
    <xsl:text>                new Uint8Array([2]), /* subscribe = 2 */
</xsl:text>
    <xsl:text>                new Uint32Array([index]),
</xsl:text>
    <xsl:text>                new Uint16Array([new_period]));
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>    send_blob(delta);
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function send_hmi_value(index, value) {
</xsl:text>
    <xsl:text>    let iectype = hmitree_types[index];
</xsl:text>
    <xsl:text>    let tobinary = typedarray_types[iectype];
</xsl:text>
    <xsl:text>    send_blob([
</xsl:text>
    <xsl:text>        new Uint8Array([0]),  /* setval = 0 */
</xsl:text>
    <xsl:text>        new Uint32Array([index]),
</xsl:text>
    <xsl:text>        tobinary(value)]);
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    // DON'T DO THAT unless read_iterator in svghmi.c modifies wbuf as well, not only rbuf
</xsl:text>
    <xsl:text>    // cache[index] = value;
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function apply_hmi_value(index, new_val) {
</xsl:text>
    <xsl:text>    let old_val = cache[index]
</xsl:text>
    <xsl:text>    if(new_val != undefined &amp;&amp; old_val != new_val)
</xsl:text>
    <xsl:text>        send_hmi_value(index, new_val);
</xsl:text>
    <xsl:text>    return new_val;
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function change_hmi_value(index, opstr) {
</xsl:text>
    <xsl:text>    let op = opstr[0];
</xsl:text>
    <xsl:text>    let given_val = opstr.slice(1);
</xsl:text>
    <xsl:text>    let old_val = cache[index]
</xsl:text>
    <xsl:text>    let new_val;
</xsl:text>
    <xsl:text>    switch(op){
</xsl:text>
    <xsl:text>      case "=":
</xsl:text>
    <xsl:text>        eval("new_val"+opstr);
</xsl:text>
    <xsl:text>        break;
</xsl:text>
    <xsl:text>      case "+":
</xsl:text>
    <xsl:text>      case "-":
</xsl:text>
    <xsl:text>      case "*":
</xsl:text>
    <xsl:text>      case "/":
</xsl:text>
    <xsl:text>        if(old_val != undefined)
</xsl:text>
    <xsl:text>            new_val = eval("old_val"+opstr);
</xsl:text>
    <xsl:text>        break;
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>    if(new_val != undefined &amp;&amp; old_val != new_val)
</xsl:text>
    <xsl:text>        send_hmi_value(index, new_val);
</xsl:text>
    <xsl:text>    return new_val;
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var current_visible_page;
</xsl:text>
    <xsl:text>var current_subscribed_page;
</xsl:text>
    <xsl:text>var current_page_index;
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function prepare_svg() {
</xsl:text>
    <xsl:text>    for(let eltid in detachable_elements){
</xsl:text>
    <xsl:text>        let [element,parent] = detachable_elements[eltid];
</xsl:text>
    <xsl:text>        parent.removeChild(element);
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function switch_page(page_name, page_index) {
</xsl:text>
    <xsl:text>    if(current_subscribed_page != current_visible_page){
</xsl:text>
    <xsl:text>        /* page switch already going */
</xsl:text>
    <xsl:text>        /* TODO LOG ERROR */
</xsl:text>
    <xsl:text>        return false;
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    if(page_name == undefined)
</xsl:text>
    <xsl:text>        page_name = current_subscribed_page;
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    let old_desc = page_desc[current_subscribed_page];
</xsl:text>
    <xsl:text>    let new_desc = page_desc[page_name];
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    if(new_desc == undefined){
</xsl:text>
    <xsl:text>        /* TODO LOG ERROR */
</xsl:text>
    <xsl:text>        return false;
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    if(page_index == undefined){
</xsl:text>
    <xsl:text>        page_index = new_desc.page_index;
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    if(old_desc){
</xsl:text>
    <xsl:text>        old_desc.absolute_widgets.map(w=&gt;w.unsub());
</xsl:text>
    <xsl:text>        old_desc.relative_widgets.map(w=&gt;w.unsub());
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>    new_desc.absolute_widgets.map(w=&gt;w.sub());
</xsl:text>
    <xsl:text>    var new_offset = page_index == undefined ? 0 : page_index - new_desc.page_index;
</xsl:text>
    <xsl:text>    new_desc.relative_widgets.map(w=&gt;w.sub(new_offset));
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    update_subscriptions();
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    current_subscribed_page = page_name;
</xsl:text>
    <xsl:text>    current_page_index = page_index;
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    jumps_need_update = true;
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    requestHMIAnimation();
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    jump_history.push([page_name, page_index]);
</xsl:text>
    <xsl:text>    if(jump_history.length &gt; 42)
</xsl:text>
    <xsl:text>        jump_history.shift();
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    return true;
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function* chain(a,b){
</xsl:text>
    <xsl:text>    yield* a;
</xsl:text>
    <xsl:text>    yield* b;
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function unsubscribe(){
</xsl:text>
    <xsl:text>    /* remove subsribers */
</xsl:text>
    <xsl:text>    for(let index of this.indexes){
</xsl:text>
    <xsl:text>        let idx = index + this.offset;
</xsl:text>
    <xsl:text>        subscribers[idx].delete(this);
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>    this.offset = 0;
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function subscribe(new_offset=0){
</xsl:text>
    <xsl:text>    /* set the offset because relative */
</xsl:text>
    <xsl:text>    this.offset = new_offset;
</xsl:text>
    <xsl:text>    /* add this's subsribers */
</xsl:text>
    <xsl:text>    for(let index of this.indexes){
</xsl:text>
    <xsl:text>        subscribers[index + new_offset].add(this);
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>    need_cache_apply.push(this); 
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function foreach_unsubscribe(){
</xsl:text>
    <xsl:text>    for(let item of this.items){
</xsl:text>
    <xsl:text>        for(let widget of item) {
</xsl:text>
    <xsl:text>            unsubscribe.call(widget);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>    this.offset = 0;
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function foreach_widgets_do(new_offset, todo){
</xsl:text>
    <xsl:text>    this.offset = new_offset;
</xsl:text>
    <xsl:text>    for(let i = 0; i &lt; this.items.length; i++) {
</xsl:text>
    <xsl:text>        let item = this.items[i];
</xsl:text>
    <xsl:text>        let orig_item_index = this.index_pool[i];
</xsl:text>
    <xsl:text>        let item_index = this.index_pool[i+this.item_offset];
</xsl:text>
    <xsl:text>        let item_index_offset = item_index - orig_item_index;
</xsl:text>
    <xsl:text>        for(let widget of item) {
</xsl:text>
    <xsl:text>            todo.call(widget, new_offset + item_index_offset);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function foreach_subscribe(new_offset=0){
</xsl:text>
    <xsl:text>    foreach_widgets_do.call(this, new_offset, subscribe);
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function widget_apply_cache() {
</xsl:text>
    <xsl:text>    for(let index of this.indexes){
</xsl:text>
    <xsl:text>        /* dispatch current cache in newly opened page widgets */
</xsl:text>
    <xsl:text>        let realindex = index+this.offset;
</xsl:text>
    <xsl:text>        let cached_val = cache[realindex];
</xsl:text>
    <xsl:text>        if(cached_val != undefined)
</xsl:text>
    <xsl:text>            dispatch_value_to_widget(this, realindex, cached_val, cached_val);
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function foreach_apply_cache() {
</xsl:text>
    <xsl:text>    foreach_widgets_do.call(this, this.offset, widget_apply_cache);
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function foreach_onclick(opstr, evt) {
</xsl:text>
    <xsl:text>    new_item_offset = eval(String(this.item_offset)+opstr)
</xsl:text>
    <xsl:text>    if(new_item_offset + this.items.length &gt; this.index_pool.length) {
</xsl:text>
    <xsl:text>        if(this.item_offset + this.items.length == this.index_pool.length)
</xsl:text>
    <xsl:text>            new_item_offset = 0;
</xsl:text>
    <xsl:text>        else
</xsl:text>
    <xsl:text>            new_item_offset = this.index_pool.length - this.items.length;
</xsl:text>
    <xsl:text>    } else if(new_item_offset &lt; 0) {
</xsl:text>
    <xsl:text>        if(this.item_offset == 0)
</xsl:text>
    <xsl:text>            new_item_offset = this.index_pool.length - this.items.length;
</xsl:text>
    <xsl:text>        else
</xsl:text>
    <xsl:text>            new_item_offset = 0;
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>    this.item_offset = new_item_offset;
</xsl:text>
    <xsl:text>    off = this.offset;
</xsl:text>
    <xsl:text>    foreach_unsubscribe.call(this);
</xsl:text>
    <xsl:text>    foreach_subscribe.call(this,off);
</xsl:text>
    <xsl:text>    update_subscriptions();
</xsl:text>
    <xsl:text>    need_cache_apply.push(this);
</xsl:text>
    <xsl:text>    jumps_need_update = true;
</xsl:text>
    <xsl:text>    requestHMIAnimation();
</xsl:text>
    <xsl:text>}
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function switch_visible_page(page_name) {
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    let old_desc = page_desc[current_visible_page];
</xsl:text>
    <xsl:text>    let new_desc = page_desc[page_name];
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    if(old_desc){
</xsl:text>
    <xsl:text>        for(let eltid in old_desc.required_detachables){
</xsl:text>
    <xsl:text>            if(!(eltid in new_desc.required_detachables)){
</xsl:text>
    <xsl:text>                let [element, parent] = old_desc.required_detachables[eltid];
</xsl:text>
    <xsl:text>                parent.removeChild(element);
</xsl:text>
    <xsl:text>            }
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>        for(let eltid in new_desc.required_detachables){
</xsl:text>
    <xsl:text>            if(!(eltid in old_desc.required_detachables)){
</xsl:text>
    <xsl:text>                let [element, parent] = new_desc.required_detachables[eltid];
</xsl:text>
    <xsl:text>                parent.appendChild(element);
</xsl:text>
    <xsl:text>            }
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    }else{
</xsl:text>
    <xsl:text>        for(let eltid in new_desc.required_detachables){
</xsl:text>
    <xsl:text>            let [element, parent] = new_desc.required_detachables[eltid];
</xsl:text>
    <xsl:text>            parent.appendChild(element);
</xsl:text>
    <xsl:text>        }
</xsl:text>
    <xsl:text>    }
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    svg_root.setAttribute('viewBox',new_desc.bbox.join(" "));
</xsl:text>
    <xsl:text>    current_visible_page = page_name;
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function update_jumps() {
</xsl:text>
    <xsl:text>    page_desc[current_visible_page].jumps.map(w=&gt;w.notify_page_change(current_visible_page,current_page_index));
</xsl:text>
    <xsl:text>    jumps_need_update = false;
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>// Once connection established
</xsl:text>
    <xsl:text>ws.onopen = function (evt) {
</xsl:text>
    <xsl:text>    init_widgets();
</xsl:text>
    <xsl:text>    send_reset();
</xsl:text>
    <xsl:text>    // show main page
</xsl:text>
    <xsl:text>    prepare_svg();
</xsl:text>
    <xsl:text>    switch_page(default_page);
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>ws.onclose = function (evt) {
</xsl:text>
    <xsl:text>    // TODO : add visible notification while waiting for reload
</xsl:text>
    <xsl:text>    console.log("Connection closed. code:"+evt.code+" reason:"+evt.reason+" wasClean:"+evt.wasClean+" Reload in 10s.");
</xsl:text>
    <xsl:text>    // TODO : re-enable auto reload when not in debug
</xsl:text>
    <xsl:text>    //window.setTimeout(() =&gt; location.reload(true), 10000);
</xsl:text>
    <xsl:text>    alert("Connection closed. code:"+evt.code+" reason:"+evt.reason+" wasClean:"+evt.wasClean+".");
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var xmlns = "http://www.w3.org/2000/svg";
</xsl:text>
    <xsl:text>var edit_callback;
</xsl:text>
    <xsl:text>function edit_value(path, valuetype, callback, initial) {
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    let [keypadid, xcoord, ycoord] = keypads[valuetype];
</xsl:text>
    <xsl:text>    console.log('XXX TODO : Edit value', path, valuetype, callback, initial, keypadid);
</xsl:text>
    <xsl:text>    edit_callback = callback;
</xsl:text>
    <xsl:text>    let widget = hmi_widgets[keypadid];
</xsl:text>
    <xsl:text>    widget.start_edit(path, valuetype, callback, initial);
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>var current_modal; /* TODO stack ?*/
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function show_modal() {
</xsl:text>
    <xsl:text>    let [element, parent] = detachable_elements[this.element.id];
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    tmpgrp = document.createElementNS(xmlns,"g");
</xsl:text>
    <xsl:text>    tmpgrpattr = document.createAttribute("transform");
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    let [xcoord,ycoord] = this.coordinates;
</xsl:text>
    <xsl:text>    let [xdest,ydest] = page_desc[current_visible_page].bbox;
</xsl:text>
    <xsl:text>    tmpgrpattr.value = "translate("+String(xdest-xcoord)+","+String(ydest-ycoord)+")";
</xsl:text>
    <xsl:text>    tmpgrp.setAttributeNode(tmpgrpattr);
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    tmpgrp.appendChild(element);
</xsl:text>
    <xsl:text>    parent.appendChild(tmpgrp);
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    current_modal = [this.element.id, tmpgrp];
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function end_modal() {
</xsl:text>
    <xsl:text>    let [eltid, tmpgrp] = current_modal;
</xsl:text>
    <xsl:text>    let [element, parent] = detachable_elements[this.element.id];
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    parent.removeChild(tmpgrp);
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>    current_modal = undefined;
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>
</xsl:text>
    <xsl:text>function widget_active_activable(eltsub) {
</xsl:text>
    <xsl:text>    if(eltsub.inactive_style === undefined)
</xsl:text>
    <xsl:text>        eltsub.inactive_style = eltsub.inactive.getAttribute("style");
</xsl:text>
    <xsl:text>    eltsub.inactive.setAttribute("style", "display:none");
</xsl:text>
    <xsl:text>    if(eltsub.active_style !== undefined)
</xsl:text>
    <xsl:text>            eltsub.active.setAttribute("style", eltsub.active_style);
</xsl:text>
    <xsl:text>    console.log("active", eltsub);
</xsl:text>
    <xsl:text>};
</xsl:text>
    <xsl:text>function widget_inactive_activable(eltsub) {
</xsl:text>
    <xsl:text>    if(eltsub.active_style === undefined)
</xsl:text>
    <xsl:text>        eltsub.active_style = eltsub.active.getAttribute("style");
</xsl:text>
    <xsl:text>    eltsub.active.setAttribute("style", "display:none");
</xsl:text>
    <xsl:text>    if(eltsub.inactive_style !== undefined)
</xsl:text>
    <xsl:text>            eltsub.inactive.setAttribute("style", eltsub.inactive_style);
</xsl:text>
    <xsl:text>    console.log("inactive", eltsub);
</xsl:text>
    <xsl:text>};
</xsl:text>
  </xsl:template>
</xsl:stylesheet>
