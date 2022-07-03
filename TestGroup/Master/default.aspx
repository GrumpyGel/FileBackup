<%@ Page language="C#" Debug="true" %>
<%@ Import Namespace="System"%>
<%@ Import Namespace="System.IO"%>
<%@ Import Namespace="System.Xml"%>
<%@ Import Namespace="System.Xml.Xsl"%>
<%@ Import Namespace="System.Runtime.InteropServices"%>


<!--#include file="mdz_Routines.aspx"-->


<script language="C#" runat="server">

  void Page_Load(object sender, System.EventArgs e)
  {
    mdz_HitInitialise();

    switch (mdz_Action) {
      case "sudokuinfo":       act_SudokuInfo();        break;
      case "sudokubesttimes":  act_SudokuBestTimes();   break;
      default:                 act_Home();              break; }

    mdz_HitComplete();
  }
	
</script>
