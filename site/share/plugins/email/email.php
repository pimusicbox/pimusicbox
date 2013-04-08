<?php

require_once(dirname(__FILE__).'/../../includes/global.inc.php');

// Set this to the email address you wish to send email from.
// Leave it null to use the server default.
define(MAIL_SENDER, null);

// The subject of the email to send. (Eg. "You've got new message about iBegin Share")
function generateEmailSubject($title, $link, $from_name, $from_email, $to_name, $to_email)
{
    return "{$from_name} wants you to see this link";
}
// The plain text body of the email to send
function generateEmailBody($title, $link, $from_name, $from_email, $to_name, $to_email, $message=null)
{
    $output = array();
    $output[] = $from_name . ' thought you might find this link interesting:';
    $output[] = '';
    $output[] = 'Title: ' . $title;
    $output[] = 'Link: ' . $link;
    if ($message) $output[] = 'Message: ' . iBeginShare::messageFilter($message);
    $output[] = '';
    $output[] = '-----------------------------';
    $output[] = $from_name . ' is using iBegin Share (http://www.ibegin.com/labs/share/)';
    $output[] = '-----------------------------';
    return implode("\r\n", $output);
}

header("Content-Type: text/plain");
if (empty($_GET['from_name']) || empty($_GET['from_email']) || empty($_GET['to_email']) || empty($_GET['to_name']))
{
    header("HTTP/1.1 400 Bad Request");
    echo 'Please fill in all required fields.';
    exit;
}
elseif (!iBeginShare::isValidEmail(trim($_GET['from_email'])))
{
    header("HTTP/1.1 400 Bad Request");
    echo 'Your email email is invalid.';
    exit;
}
elseif (!iBeginShare::isValidEmail(trim($_GET['to_email'])))
{
    header("HTTP/1.1 400 Bad Request");
    echo 'Your friend\'s email is invalid.';
    exit;
}
else
{
    $subject = generateEmailSubject($_GET['title'], $_GET['link'], $_GET['from_name'], $_GET['from_email'], $_GET['to_name'], $_GET['to_email']);
    $body = generateEmailBody($_GET['title'], $_GET['link'], $_GET['from_name'], $_GET['from_email'], $_GET['to_name'], $_GET['to_email'], $_GET['message']);

    $from = $_GET['from_name']. '<'.$_GET['from_email'].'>';
    $to = $_GET['to_name']. '<'.$_GET['to_email'].'>';

    $headers = array();
    $headers[] = 'From: ' . $from;
    $headers[] = 'Reply-To: ' . $from;
    $headers[] = 'X-Mailer: iBeginShare (PHP/' . phpversion() . ')';
    $headers = implode("\r\n", $headers);
        
    if (@mail($to, $subject, $body, $headers))
    {
        echo 'Your email was sent successfully.';
        exit;
    }
    else
    {
        header("HTTP/1.1 500 Internal Server Error");
        echo 'Unknown error sending the email.';
        exit;
    }
}

?>