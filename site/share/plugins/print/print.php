<?php

require_once(dirname(__FILE__).'/../../includes/global.inc.php');

header('Content-Type: text/html');
echo $raw_content . '<script type="text/javascript">window.print();</script>';

?>