<?php
/*
This script is supposed to be used together with the HTML2FPDF.php class
Copyright (C) 2004-2005 Renato Coelho
*/

function ConvertColor($color="#000000"){
//returns an associative array (keys: R,G,B) from html code (e.g. #3FE5AA)

  //W3C approved color array (disabled)
  //static $common_colors = array('black'=>'#000000','silver'=>'#C0C0C0','gray'=>'#808080', 'white'=>'#FFFFFF','maroon'=>'#800000','red'=>'#FF0000','purple'=>'#800080','fuchsia'=>'#FF00FF','green'=>'#008000','lime'=>'#00FF00','olive'=>'#808000','yellow'=>'#FFFF00','navy'=>'#000080', 'blue'=>'#0000FF','teal'=>'#008080','aqua'=>'#00FFFF');
  //All color names array
  static $common_colors = array('antiquewhite'=>'#FAEBD7','aquamarine'=>'#7FFFD4','beige'=>'#F5F5DC','black'=>'#000000','blue'=>'#0000FF','brown'=>'#A52A2A','cadetblue'=>'#5F9EA0','chocolate'=>'#D2691E','cornflowerblue'=>'#6495ED','crimson'=>'#DC143C','darkblue'=>'#00008B','darkgoldenrod'=>'#B8860B','darkgreen'=>'#006400','darkmagenta'=>'#8B008B','darkorange'=>'#FF8C00','darkred'=>'#8B0000','darkseagreen'=>'#8FBC8F','darkslategray'=>'#2F4F4F','darkviolet'=>'#9400D3','deepskyblue'=>'#00BFFF','dodgerblue'=>'#1E90FF','firebrick'=>'#B22222','forestgreen'=>'#228B22','gainsboro'=>'#DCDCDC','gold'=>'#FFD700','gray'=>'#808080','green'=>'#008000','greenyellow'=>'#ADFF2F','hotpink'=>'#FF69B4','indigo'=>'#4B0082','khaki'=>'#F0E68C','lavenderblush'=>'#FFF0F5','lemonchiffon'=>'#FFFACD','lightcoral'=>'#F08080','lightgoldenrodyellow'=>'#FAFAD2','lightgreen'=>'#90EE90','lightsalmon'=>'#FFA07A','lightskyblue'=>'#87CEFA','lightslategray'=>'#778899','lightyellow'=>'#FFFFE0','limegreen'=>'#32CD32','magenta'=>'#FF00FF','mediumaquamarine'=>'#66CDAA','mediumorchid'=>'#BA55D3','mediumseagreen'=>'#3CB371','mediumspringgreen'=>'#00FA9A','mediumvioletred'=>'#C71585','mintcream'=>'#F5FFFA','moccasin'=>'#FFE4B5','navy'=>'#000080','olive'=>'#808000','orange'=>'#FFA500','orchid'=>'#DA70D6','palegreen'=>'#98FB98','palevioletred'=>'#D87093','peachpuff'=>'#FFDAB9','pink'=>'#FFC0CB','powderblue'=>'#B0E0E6','red'=>'#FF0000','royalblue'=>'#4169E1','salmon'=>'#FA8072','seagreen'=>'#2E8B57','sienna'=>'#A0522D','skyblue'=>'#87CEEB','slategray'=>'#708090','springgreen'=>'#00FF7F','tan'=>'#D2B48C','thistle'=>'#D8BFD8','turquoise'=>'#40E0D0','violetred'=>'#D02090','white'=>'#FFFFFF','yellow'=>'#FFFF00');
  //http://www.w3schools.com/css/css_colornames.asp
  if ( ($color{0} != '#') and ( strstr($color,'(') === false ) ) $color = $common_colors[strtolower($color)];

  if ($color{0} == '#') //case of #nnnnnn or #nnn
  {
  	$cor = strtoupper($color);
  	if (strlen($cor) == 4) // Turn #RGB into #RRGGBB
  	{
	 	  $cor = "#" . $cor{1} . $cor{1} . $cor{2} . $cor{2} . $cor{3} . $cor{3};
	  }  
	  $R = substr($cor, 1, 2);
	  $vermelho = hexdec($R);
	  $V = substr($cor, 3, 2);
	  $verde = hexdec($V);
	  $B = substr($cor, 5, 2);
	  $azul = hexdec($B);
	  $color = array();
	  $color['R']=$vermelho;
	  $color['G']=$verde;
	  $color['B']=$azul;
  }
  else //case of RGB(r,g,b)
  {
  	$color = str_replace("rgb(",'',$color); //remove ´rgb(´
  	$color = str_replace("RGB(",'',$color); //remove ´RGB(´ -- PHP < 5 does not have str_ireplace
  	$color = str_replace(")",'',$color); //remove ´)´
    $cores = explode(",", $color);
    $color = array();
	  $color['R']=$cores[0];
	  $color['G']=$cores[1];
	  $color['B']=$cores[2];
  }
  if (empty($color)) return array('R'=>255,'G'=>255,'B'=>255);
  else return $color; // array['R']['G']['B']
}

function ConvertSize($size=5,$maxsize=0){
// Depends of maxsize value to make % work properly. Usually maxsize == pagewidth
  //Identify size (remember: we are using 'mm' units here)
  if ( stristr($size,'px') ) $size *= 0.2645; //pixels
  elseif ( stristr($size,'cm') ) $size *= 10; //centimeters
  elseif ( stristr($size,'mm') ) $size += 0; //millimeters
  elseif ( stristr($size,'in') ) $size *= 25.4; //inches 
  elseif ( stristr($size,'pc') ) $size *= 38.1/9; //PostScript picas 
  elseif ( stristr($size,'pt') ) $size *= 25.4/72; //72dpi
  elseif ( stristr($size,'%') )
  {
  	$size += 0; //make "90%" become simply "90" 
  	$size *= $maxsize/100;
  }
  else $size *= 0.2645; //nothing == px
  
  return $size;
}

function value_entity_decode($html)
{
//replace each value entity by its respective char
  preg_match_all('|&#(.*?);|',$html,$temparray);
  foreach($temparray[1] as $val) $html = str_replace("&#".$val.";",chr($val),$html);
  return $html;
}

function lesser_entity_decode($html)
{
  //supports the most used entity codes
 	$html = str_replace("&nbsp;"," ",$html);
 	$html = str_replace("&amp;","&",$html);
 	$html = str_replace("&lt;","<",$html);
 	$html = str_replace("&gt;",">",$html);
 	$html = str_replace("&laquo;","«",$html);
 	$html = str_replace("&raquo;","»",$html);
 	$html = str_replace("&para;","¶",$html);
 	$html = str_replace("&euro;","€",$html);
 	$html = str_replace("&trade;","™",$html);
 	$html = str_replace("&copy;","©",$html);
 	$html = str_replace("&reg;","®",$html);
 	$html = str_replace("&plusmn;","±",$html);
 	$html = str_replace("&tilde;","~",$html);
 	$html = str_replace("&circ;","^",$html);
 	$html = str_replace("&quot;",'"',$html);
 	$html = str_replace("&permil;","‰",$html);
 	$html = str_replace("&Dagger;","‡",$html);
 	$html = str_replace("&dagger;","†",$html);
  return $html;
}

function AdjustHTML($html,$usepre=true)
{
//Try to make the html text more manageable (turning it into XHTML)

  //Remove javascript code from HTML (should not appear in the PDF file)
  $regexp = '|<script.*?</script>|si';
  $html = preg_replace($regexp,'',$html);

 	$html = str_replace("\r\n","\n",$html); //replace carriagereturn-linefeed-combo by a simple linefeed
 	$html = str_replace("\f",'',$html); //replace formfeed by nothing
	$html = str_replace("\r",'',$html); //replace carriage return by nothing
 	if ($usepre) //used to keep \n on content inside <pre> and inside <textarea>
 	{
    // Preserve '\n's in content between the tags <pre> and </pre>
  	$regexp = '#<pre(.*?)>(.+?)</pre>#si';
  	$thereispre = preg_match_all($regexp,$html,$temp);
    // Preserve '\n's in content between the tags <textarea> and </textarea>
  	$regexp2 = '#<textarea(.*?)>(.+?)</textarea>#si';
  	$thereistextarea = preg_match_all($regexp2,$html,$temp2);
  	$html = str_replace("\n",' ',$html); //replace linefeed by spaces
  	$html = str_replace("\t",' ',$html); //replace tabs by spaces
	  $regexp3 = '#\s{2,}#s'; // turn 2+ consecutive spaces into one
	  $html = preg_replace($regexp3,' ',$html);
   	$iterator = 0;
  	while($thereispre) //Recover <pre attributes>content</pre>
  	{
      $temp[2][$iterator] = str_replace("\n","<br>",$temp[2][$iterator]);
    	$html = preg_replace($regexp,'<erp'.$temp[1][$iterator].'>'.$temp[2][$iterator].'</erp>',$html,1);
    	$thereispre--;
    	$iterator++;
    }
    $iterator = 0;
    while($thereistextarea) //Recover <textarea attributes>content</textarea>
	  {
      $temp2[2][$iterator] = str_replace(" ","&nbsp;",$temp2[2][$iterator]);
    	$html = preg_replace($regexp2,'<aeratxet'.$temp2[1][$iterator].'>'.trim($temp2[2][$iterator]).'</aeratxet>',$html,1);
    	$thereistextarea--;
    	$iterator++;
    }
    //Restore original tag names
    $html = str_replace("<erp","<pre",$html);
    $html = str_replace("</erp>","</pre>",$html);
    $html = str_replace("<aeratxet","<textarea",$html);
    $html = str_replace("</aeratxet>","</textarea>",$html);
  // (the code above might slowdown overall performance?)
  } //end of if($usepre)
  else
  {
  	$html = str_replace("\n",' ',$html); //replace linefeed by spaces
  	$html = str_replace("\t",' ',$html); //replace tabs by spaces
	  $regexp = '/\\s{2,}/s'; // turn 2+ consecutive spaces into one
  	$html = preg_replace($regexp,' ',$html);
  }
  // remove redundant <br>'s before </div>, avoiding huge leaps between text blocks
  // such things appear on computer-generated HTML code  
	$regexp = '/(<br[ \/]?[\/]?>)+?<\/div>/si'; //<?//fix PSPAD highlight bug
	$html = preg_replace($regexp,'</div>',$html);
	return $html;
}

function dec2alpha($valor,$toupper="true"){
// returns a string from A-Z to AA-ZZ to AAA-ZZZ
// OBS: A = 65 ASCII TABLE VALUE
  if (($valor < 1)  || ($valor > 18278)) return "?"; //supports 'only' up to 18278
  $c1 = $c2 = $c3 = '';
  if ($valor > 702) // 3 letters (up to 18278)
    {
      $c1 = 65 + floor(($valor-703)/676);
      $c2 = 65 + floor((($valor-703)%676)/26);
      $c3 = 65 + floor((($valor-703)%676)%26);
    }
  elseif ($valor > 26) // 2 letters (up to 702)
  {
      $c1 = (64 + (int)(($valor-1) / 26));
      $c2 = (64 + (int)($valor % 26));
      if ($c2 == 64) $c2 += 26;
  }
  else // 1 letter (up to 26)
  {
      $c1 = (64 + $valor);
  }
  $alpha = chr($c1);
  if ($c2 != '') $alpha .= chr($c2);
  if ($c3 != '') $alpha .= chr($c3);
  if (!$toupper) $alpha = strtolower($alpha);
  return $alpha;
}

function dec2roman($valor,$toupper=true){
//returns a string as a roman numeral
  if (($valor >= 5000) || ($valor < 1)) return "?"; //supports 'only' up to 4999
  $aux = (int)($valor/1000);
  if ($aux!==0)
  {
    $valor %= 1000;
    while($aux!==0)
    {
    	$r1 .= "M";
    	$aux--;
    }
  }
  $aux = (int)($valor/100);
  if ($aux!==0)
  {
    $valor %= 100;
    switch($aux){
    	case 3: $r2="C";
    	case 2: $r2.="C";
    	case 1: $r2.="C"; break;
  	  case 9: $r2="CM"; break;
  	  case 8: $r2="C";
  	  case 7: $r2.="C";
    	case 6: $r2.="C";
      case 5: $r2="D".$r2; break;
      case 4: $r2="CD"; break;
      default: break;
	  }
  }
  $aux = (int)($valor/10);
  if ($aux!==0)
  {
    $valor %= 10;
    switch($aux){
    	case 3: $r3="X";
    	case 2: $r3.="X";
    	case 1: $r3.="X"; break;
    	case 9: $r3="XC"; break;
    	case 8: $r3="X";
    	case 7: $r3.="X";
  	  case 6: $r3.="X";
      case 5: $r3="L".$r3; break;
      case 4: $r3="XL"; break;
      default: break;
    }
  }
  switch($valor){
  	case 3: $r4="I";
  	case 2: $r4.="I";
  	case 1: $r4.="I"; break;
  	case 9: $r4="IX"; break;
  	case 8: $r4="I";
    case 7: $r4.="I";
    case 6: $r4.="I";
    case 5: $r4="V".$r4; break;
    case 4: $r4="IV"; break;
    default: break;
  }
  $roman = $r1.$r2.$r3.$r4;
  if (!$toupper) $roman = strtolower($roman);
  return $roman;
}	

?>
