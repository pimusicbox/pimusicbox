<?php

require_once(dirname(__FILE__).'/includes/global.inc.php');

$ibegin_stats_times = array(
    'all'       => 'All Time',
    'today'     => 'Today',
    'week'      => '7 Days',
    'month'     => '30 Days',
);
$ibegin_stats_times_values = array(
    'all'       => 0,
    'today'     => time()-60*60*24,
    'week'      => time()-60*60*24*7,
    'month'     => time()-60*60*24*30,
);

if ($_GET['fy'] && $_GET['ty'])
   {
       // using date range
       $start = mktime(0, 0, 0, $_GET['fm'] ? $_GET['fm'] : 0, $_GET['fd'] ? $_GET['fd'] : 0, $_GET['fy']);
       $end = mktime(0, 0, 0, $_GET['tm'] ? $_GET['tm'] : 0, $_GET['td'] ? $_GET['td'] : 0, $_GET['ty']);
       if ($_GET['td']) $end += 60*60*24;
       $from = array($_GET['fm'], $_GET['fd'], $_GET['fy']);
       $to = array($_GET['tm'], $_GET['td'], $_GET['ty']);
   }
   else
   {
       $time = $_GET['time'];
       if (!array_key_exists($time, $ibegin_stats_times)) $time = 'all';
       $start = $ibegin_stats_times_values[$time];
       $end = time();
       if ($start == 0) $from = array();
       else $from = explode('/', date('n/j/Y', $start));
       $to = explode('/', date('n/j/Y', $end));
   }

   $months_array = array();
   for ($i=1; $i<=12; $i++)
   {
       $months_array[$i] = date('F', mktime(0, 0, 0, $i));
   }
   list($current_month, $current_day, $current_year) = explode('/', date('F/j/Y'));

   ob_start();
   $total = $db_link->query_result_single(sprintf("SELECT COUNT(*) as `total` FROM `".IBEGIN_SHARE_TABLE_PREFIX."log` WHERE `timestamp` > %d AND `timestamp` < %d", $start, $end));
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>iBegin Share Stats</title>
    <link rel="stylesheet" href="../readme/global.css" type="text/css" media="screen"/>
    <link rel="stylesheet" type="text/css" media="screen" href="share.css?3" />
    <style type="text/css">
    .stats .progress_bar { padding: 1px; overflow: hidden; border: 1px solid #ccc; }
    .stats .progress_bar strong { font-weight: normal; background: #e3e3e3; display: block; padding: 5px; font-size: 1em; }
    .stats .progress_bar strong span { color: #999; font-size: 0.9em; }
    .stats th { text-align: left; }
    .stats .tc { text-align: center; }
    .stats tr:hover td { background: #f3f3f3; }
    .stats tr:hover .progress_bar strong { background: #d3d3d3; }
    .stats_selector .selector, #timestampdiv { position: absolute; right: 0; }
    .stats_selector { position: relative; }
    .stats_selector .selector { margin-top: -10px; }
    .stats_selector form div { clear: left; }
    .clear { clear: both; }
    #date_wrap { position: relative; }
    #date_wrap #timestampdiv { width: 270px; background: #f9f9f9; border: 1px solid #8DD6E2; top: 100%; margin-top: 1px; z-index: 100000; padding: 15px; display: none; } 
    #date_wrap label { float: left; display: block; width: 60px; padding: 4px 0; }
    #date_wrap .text { border: 1px solid #ccc; }
    .widget { width: 380px; float: left; margin: 5px; border: 1px solid #ccc; }
    .widget td { padding: 0; line-height: 100%; }
    .widget table { border: 0; }
    .widget .title { background: #333; padding: 5px; margin: 1px; }
    .widget .title h3 { margin: 0; color: #fff; }
    .widget .body { height: 250px; overflow: auto; padding: 5px; margin: 1px; }
    </style>
    <script type="text/javascript">
    function ibsToggleDate() {
       var el = document.getElementById('timestampdiv');
       if (el.style.display == 'block') el.style.display = 'none';
       else el.style.display = 'block';
   }
   </script>
    <script src="share.js?2" type="text/javascript"></script>
    <script type="text/javascript">iBeginShare.base_url = '';</script>
</head>


<body>
    <div id="top">
        <div id="header">
            <h1>iBegin Share <span>Stats</span></h1>
            <h4>Brought to you by <a href="http://www.ibegin.com/labs/">iBegin Labs</a></h4>
        </div>

        <div class="stats_selector"><div class="selector">
            <p><strong>View Stats:</strong> <?php
            $i = 0;
            foreach ($ibegin_stats_times as $key=>$value)
            {
                if ($i != 0) echo ' | ';
                if ($key == $time) echo '<strong>'.htmlspecialchars($value).'</strong>';
                else echo '<a href="stats.php?time='.$key.'">'.htmlspecialchars($value).'</a>';
                $i += 1;
            }
            ?> | <span id="date_wrap"><a href="javascript:ibsToggleDate();">Select Dates</a><form id="timestampdiv" method="get" action="stats.php">
                <div><label>From:</label> <select name="fm"><?php
                foreach ($months_array as $key=>$month_name)
                {
                    echo '<option value="'.$key.'"';
                    if ($from[0] == $key || (!$from[0] && $month_name == $current_month)) echo ' selected="selected"';
                    echo '>'.$month_name.'</option>';
                }
                ?></select>, <input type="text" autocomplete="off" name="fd" maxlength="2" size="2" value="<?php echo $from[1] ? $from[1] : $current_day; ?>" class="text" /> <input type="text" name="fy" maxlength="5" size="4" value="<?php echo $from[2] ? $from[2] : $current_year; ?>" class="text"/></div>
                <div><label>To:</label> <select name="tm"><?php
                foreach ($months_array as $key=>$month_name)
                {
                    echo '<option value="'.$key.'"';
                    if ($to[0] == $key || (!$to[0] && $month_name == $current_month)) echo ' selected="selected"';
                    echo '>'.$month_name.'</option>';
                }
                ?></select>, <input type="text" autocomplete="off" name="td" maxlength="2" size="2" value="<?php echo $to[1] ? $to[1] : $current_day; ?>" class="text" /> <input type="text" name="ty" maxlength="5" size="4" value="<?php echo $to[2] ? $to[2] : $current_year; ?>" class="text"/></div>
                <div style="text-align: right; margin-top: 5px;"><input type="submit" value="Show Me" class="button" /></div>
               </form></span>
           </p>
       </div>
       <h2>iBegin Share Statistics</h2></div>
       <?php if ($total) { ?>
           <div class="widget">
               <div class="title"><h3>Overview</h3></div>
               <div class="body">
                   <table class="stats" width="100%" cellspacing="3" cellpadding="3">
                       <thead>
                           <tr>
                               <th>Action</th>
                               <th style="width: 50px;" class="tc">Hits</th>
                           </tr>
                       </thead>
                       <tbody>
                       <?php
                       $q = $db_link->query("SELECT `action`, COUNT(*) as `total` FROM `".IBEGIN_SHARE_TABLE_PREFIX."log` WHERE `timestamp` > %d AND `timestamp` < %d GROUP BY `action` ORDER BY `total` DESC", $start, $end);
                       while ($row =& $db_link->fetch_array($q))
                       {
                           $percent = round($row['total']/$total*100);
                           ?><tr>
                               <td class="progress_bar"><strong style="width: <?php echo $percent; ?>%"><?php echo htmlspecialchars(ucfirst($row['action'])); ?></strong></td>
                               <td class="tc"><?php echo $row['total']; ?><br /><small>(<?php echo $percent; ?>%)</small></td>
                           </tr><?php
                       }
                       ?>
                       </tbody>
                   </table>
               </div>
           </div>

           <div class="widget">
               <div class="title"><h3>Top Pages</h3></div>
               <div class="body">
                  <table class="stats" width="100%" cellspacing="3" cellpadding="3">
                    <thead>
                       <tr>
                           <th>Page</th>
                           <th style="width: 50px;" class="tc">Hits</th>
                       </tr>
                    </thead>
                    <tbody>
                    <?php
                    $q = $db_link->query("SELECT `link`, COUNT(*) as `total` FROM `".IBEGIN_SHARE_TABLE_PREFIX."log` WHERE `timestamp` > %d AND `timestamp` < %d GROUP BY `link` ORDER BY `total` DESC LIMIT 0, 10", $start, $end);
                    while ($row =& $db_link->fetch_array($q))
                    {
                       $percent = round($row['total']/$total*100);
                       ?><tr>
                           <td class="progress_bar"><strong style="width: <?php echo $percent; ?>%"><?php echo ($row['link'] ? '<a href="'.$row['link'].'">'.htmlspecialchars(wordwrap($row['link'], 30, ' ', true)).'</a>' : '<em>No Link</em>'); ?></strong></td>
                           <td class="tc"><?php echo $row['total']; ?><br /><small>(<?php echo $percent; ?>%)</small></td>
                       </tr><?php
                    }
                    ?>
                    </tbody>
                  </table>
                </div>
            </div>

            <div class="clear"></div>
            <h2>Plugin Usage</h2>
            <?php
            $q = $db_link->query("SELECT `action`, COUNT(*) as `total` FROM `".IBEGIN_SHARE_TABLE_PREFIX."log` WHERE `timestamp` > %d AND `timestamp` < %d GROUP BY `action` ORDER BY `total` DESC", $start, $end);
            while ($row =& $db_link->fetch_array($q))
            {
               $sq = $db_link->query("SELECT `label`, COUNT(*) as `total` FROM `".IBEGIN_SHARE_TABLE_PREFIX."log` WHERE `timestamp` > %d AND `timestamp` < %d AND `action` = %s GROUP BY `label` ORDER BY `total` DESC", $start, $end, $db_link->escape_string($row['action']));
               ?>
               <div class="widget">
                   <div class="title"><h3><?php echo htmlspecialchars(ucfirst($row['action'])); ?></h3></div>
                   <div class="body">
                       <table class="stats" width="100%" cellspacing="3" cellpadding="3">
                               <thead>
                                   <tr>
                                       <th>Label</th>
                                       <th style="width: 50px;" class="tc">Hits</th>
                                   </tr>
                               </thead>
                               <tbody>
                               <?php

                               while ($srow =& $db_link->fetch_array($sq))
                               {
                                   $percent = round($srow['total']/$row['total']*100);
                                   ?><tr>
                                       <td class="progress_bar"><strong style="width: <?php echo $percent; ?>%"><?php echo ($srow['label'] ? htmlspecialchars($srow['label']) : '<em>Default Action</em>'); ?></strong></td>
                                       <td class="tc"><?php echo $srow['total']; ?><br /><small>(<?php echo $percent; ?>%)</small></td>
                                   </tr><?php
                               }
                               ?>
                               </tbody>
                           </table>
                    </div>
                </div>
               <?php
           }
           ?>
           <br class='clear' />
       <?php } else { ?>
           <p>There are no statistics available for these dates.</p>
       <?php } ?>

    </div>
</body>
</html>