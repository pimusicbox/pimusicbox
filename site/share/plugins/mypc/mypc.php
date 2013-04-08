<?php

require_once(dirname(__FILE__).'/../../includes/global.inc.php');

// pdf was breaking
define(RELATIVE_PATH, '');

switch ($_GET['action'])
{
    case 'word':
        require_once(dirname(__FILE__).'/HTML2Doc.php');
        $doc = new HTML_TO_DOC();
        $doc->setTitle(iBeginShare::quoteSmart($_GET['title']));
        $doc->createDoc($raw_content,((strlen(iBeginShare::quoteSmart($_GET['title'])) > 0)?str_replace(' ','-',strip_tags($_GET['title'])):'Document-'.date('Y-m-d')).'.doc');
    break;
    case 'pdf':
        require_once(dirname(__FILE__).'/html2fpdf/html2fpdf.php');
        $pdf = new HTML2FPDF();
        $pdf->DisplayPreferences($_GET['title']);
        $pdf->AddPage();
        $pdf->WriteHTML(html_entity_decode($raw_content));
        $pdf->Output(((strlen(iBeginShare::quoteSmart($_GET['title'])) > 0)?str_replace(' ','-',strip_tags($_GET['title'])):'Document-'.date('Y-m-d')).'.pdf' ,'D');
    break;
}
?>