<?php
/*
 Copyright (C) 2004 Renato Coelho 
 (PHP)Source 2 Doc v0.5.0
 This is a simple script created in order to update the HTML2FPDF page
 It should make a php class documentation
 LICENSE: Freeware.
 Lacks: html_decode and the likes 
 Plans: make an independent table for each part?

 Usage:
 
 require_once('source2doc.php');
 echo source2doc('filename.php'); //Print doc info on browser
 
 HOW TO declare var types and HOW TO use @return and @desc: (//! is a one-line comment) 
 
 var $name; //! type
 
 function name()
 {
 //! @return void
 //! @desc Say something in one line, but dont use tags or ';' here
 //! @desc Fale algo em uma linha, mas nao use tags ou ';' aqui
 ...}

*/

function source2doc($filename)
{
  define('endl',"\n");
  $classname = '';
  $extends = '';

	$file = fopen($filename,"r");
  $tamarquivo = filesize($filename);
  $buffer = fread($file, $tamarquivo);  
  fclose($file);

////
// Remove all PHP comments
// Leave only the special comments '//!'
////

  //Remove /* multi-line comments */
 	$regexp = '|/\\*.*?\\*/|s';
 	$buffer = preg_replace($regexp,'',$buffer);
  //Remove // one line comments 
 	$regexp = '|//[^!].*|m';
 	$buffer = preg_replace($regexp,'',$buffer);

////
// Get class name and what it extends (or not)
////
  
 	$regexp = '|class\\s+?(\\S+)(\\s+?\\S+\\s+?(\\S+))?|mi';
  preg_match($regexp,$buffer,$aux); //one class per source file
  
  $classname = $aux[1];
  if (!empty($aux[3])) $extends = $aux[3];
  else $extends = '';

  $html = '<b>CLASSNAME:</b> ' . $classname . '<br />' . endl;
  if ($extends != '') $html .= '<b>EXTENDS:</b> ' . $extends . '<br />' . endl;
  $html .= '<table border="1" width="100%">' . endl;

////
// Get constants from source code
////

  $html .= '<tr>' . endl;
  $html .= '<th bgcolor="#6191ff" colspan="2">' . endl;
  $html .= 'CONSTANTS' . endl;
  $html .= '</th>' . endl;
  $html .= '</tr>' . endl;

 	$regexp = '/define[(](.*?);/si';
  preg_match_all($regexp,$buffer,$const);

  $const = $const[0];
  for($i=0; $i < count($const) ; $i++)
  {
    $html .= '<tr>' . endl;
    $html .= '<td colspan="2">' . endl;
    $html .= '<font size=2>' . $const[$i] . '</font>' .endl;
    $html .= '</td>' . endl;
    $html .= '</tr>' . endl;
  }

////
// Get imports from source code
////

  $html .= '<tr>' . endl;
  $html .= '<th bgcolor="#6191ff" colspan="2">' . endl;
  $html .= 'IMPORTS' . endl;
  $html .= '</th>' . endl;
  $html .= '</tr>' . endl;

 	$regexp = '/((require|include)[(_].*?);/si';
  preg_match_all($regexp,$buffer,$imports);

  $imports = $imports[0];
  for($i=0; $i < count($imports) ; $i++)
  {
    $html .= '<tr>' . endl;
    $html .= '<td colspan="2">' . endl;
    $html .= '<font size=2>' . $imports[$i] . '</font>' .endl;
    $html .= '</td>' . endl;
    $html .= '</tr>' . endl;
  }

////
// Get attributes from class
////

  $html .= '<tr>' . endl;
  $html .= '<th bgcolor="#6191ff" colspan="2">' . endl;
  $html .= 'ATTRIBUTES' . endl;
  $html .= '</th>' . endl;
  $html .= '</tr>' . endl;

 	$regexp = '|var\\s(.+);\\s*(//!\\s*?(\\S+))?|mi';
  preg_match_all($regexp,$buffer,$atr);

  $vname = $atr[1];
  $vtype = $atr[3];
  
  if(!empty($vname))
  {
    $html .= '<tr>' . endl;
    $html .= '<td align="center" width="10%" bgcolor="#bbbbbb">' . endl;
    $html .= 'TYPE' . endl;
    $html .= '</td>' . endl;
    $html .= '<td align="center" width="90%" bgcolor="#bbbbbb">' . endl;
    $html .= 'NAME' . endl;
    $html .= '</td>' . endl;
    $html .= '</tr>' . endl;
  }

  for($i=0; $i < count($vname) ; $i++)
  {
    $html .= '<tr>' . endl;

    $html .= '<td align="center">' . endl;
    if (empty($vtype[$i])) $html .= '<font size=2><i>(???)</i></font>' . endl;
    else $html .= '<font size=2><i>('. $vtype[$i] .')</i></font>' . endl;
    $html .= '</td>' . endl;

    $html .= '<td>' . endl;
    $html .= '<font size=2><b>var</b> ' . $vname[$i] . ';</font>' . endl;
    $html .= '</td>' . endl;
    $html .= '</tr>' . endl;
  }

/////
// Get class' methods
/////

  $html .= '<tr>' . endl;
  $html .= '<th bgcolor="#6191ff" colspan="2">' . endl;
  $html .= 'METHODS' . endl;
  $html .= '</th>' . endl;
  $html .= '</tr>' . endl;

 	$regexp = '|function\\s([^)]*)[)].*?(//!.*?)*;|si';
  preg_match_all($regexp,$buffer,$func);
  
  $funcname = $func[1];
  $funccomment = $func[0];

  for($i=0; $i < count($funcname) ; $i++)
  {
    $html .= '<tr>' . endl;
    $html .= '<td bgcolor="#33ff99" colspan="2">' . endl;
    $html .= '<font size=2><b>function</b> ' . $funcname[$i] . ')</font>' . endl;
    $html .= '</td>' . endl;
    $html .= '</tr>' . endl;

    $desc = '';
    $ret = '';
 	  $regexp = '|//!(.*)|mi';
    preg_match_all($regexp,$funccomment[$i],$temp);
    $temp = $temp[1];

    if (empty($temp[0])) continue;
    foreach($temp as $val)
    {
      if (strstr($val,'@desc'))
      {
       	$regexp = '|.*?@desc(.*)|si';
        preg_match($regexp,$val,$temp2);
        $desc = $temp2[1];
      }
      elseif (strstr($val,'@return'))
      {
       	$regexp = '|.*?@return(.*)|si';
        preg_match($regexp,$val,$temp3);
        $ret = $temp3[1];
      }      
    }
    if ($ret != '' or $desc != '')
    {
      $html .= '<tr>' . endl;

      //@return column
      $html .= '<td width="30%">' . endl;
      if ($ret == '') $html .= '<font size=2><b>Return:</b> <i>?void?</i></font>' . endl;
      else $html .= '<font size=2><b>Return:</b> <i>' . trim($ret) . '</i></font>' . endl;
      $html .= '</td>' . endl;
      //@desc column
      $html .= '<td width="70%">' . endl;
      if ($desc == '') $html .= '<font size=2><b>OBS:</b> </font>' . endl;
      else $html .= '<font size=2><b>OBS:</b> ' . trim($desc) . '</font>' . endl;
      $html .= '</td>' . endl;

      $html .= '</tr>' . endl;
    }
  }

/////

  $html .= '</table>';

  return $html;
}

?>