<?php
/**
 * SQL functions library for PHP5
 *
 * @author David Cramer <dcramer@gmail.com
 * @package mysqldb
 * @license http://www.gnu.org/copyleft/gpl.html GNU GPL
 * @copyright 2008 David Cramer
 * @version 0.1
 */


class MySQLdb extends Database
{
    /**
     * Connect to the MySQL Server
     *
     * @return boolean
     */
    function connect($force=false)
    {
        parent::connect($force);
        if (!$this->__password)
        {
            if ($this->__pconnect == 1)
                $this->link_id = @mysql_pconnect($this->__server, $this->__username);
            else
                $this->link_id = @mysql_connect($this->__server, $this->__username);
        }
        else
        {
            if ($this->__pconnect == 1)
                $this->link_id = @mysql_pconnect($this->__server, $this->__username, $this->__password);
            else
                $this->link_id = @mysql_connect($this->__server, $this->__username, $this->__password);
        }
        if (!$this->link_id)
        {
            //$this->error(mysql_error());
            $this->error('Connection to database failed');
            return false;
        }
        $this->select_db($this->__database);

        return true;
    }

    /**
     * Selects the Database
     *
     * @param string $database
     * @return boolean
     */
    function select_db($database)
    {
        parent::select_db($database);
        if (@mysql_select_db($this->__database, $this->link_id))
            return true;
        $this->error('Cannot use database ' . $this->__database);
        return false;
    }
    
    function execute($sql)
    {
        parent::execute($sql);
        $result_id = mysql_query($sql);
        if (!$result_id) $this->error('Invalid SQL: '.$sql);
        return $result_id;
    }
    
    function fetch_array($id)
    {
        parent::fetch_array($id);
        return mysql_fetch_array($id);
    }
    
    function free_result($id)
    {
        parent::free_result($id);
        return @mysql_free_result($id);
    }
    
    function num_rows($id)
    {
        parent::num_rows($id);
        return mysql_num_rows($id);
    }
    
    function num_fields($id)
    {
        parent::num_fields($id);
        return mysql_num_fields($id);
    }

    function field_name($id, $num)
    {
        parent::field_name($id);
        return mysql_field_name($id, $num);
    }

    function insert_id()
    {
        parent::insert_id($id);
        return mysql_insert_id($this->link_id);
    }

    function close()
    {
        parent::close($id);
        return mysql_close($this->link_id);
    }

    function escape_string($string)
    {
        parent::escape_string($id);
        return mysql_escape_string($string);
    }
    
    function error($message)
    {
        if ($this->debug)
        {
            $message = $this->error(mysql_error($this->link_id));
        }
        parent::error($message);
    }
    
}
class PostgreSQLdb extends Database
{
    /**
     * Connect to the PostgreSQL Server
     *
     * @return boolean
     */
    function connect($force=false)
    {
        parent::connect();
        $params = array(
            'host='.$this->__server,
            'user='.$this->__username,
            'dbname='.$this->__database,
        );
        if ($this->__password)
            $params[] = 'password='.$this->__password;
            
        if ($this->__pconnect == 1)
            $this->link_id = @pg_connect(implode(' ', $params));
        else
            $this->link_id = @pg_pconnect(implode(' ', $params));
        if (!$this->link_id)
        {
            $this->error('Connection to database failed');
            return false;
        }
        return true;
    }

    /**
     * Selects the Database
     *
     * @param string $database
     * @return boolean
     */
    function select_db($database)
    {
        parent::select_db($database);
        pg_close($this->link_id);
        $this->__database = $database;
        $this->connect();
        return true;
    }
    
    function execute($sql)
    {
        parent::execute($sql);
        $result_id = mysql_query($sql);
        if (!$result_id) $this->error('Invalid SQL: '.$sql);
        return $result_id;
    }
    
    function fetch_array($id)
    {
        parent::fetch_array($id);
        return @pg_fetch_array($id);
    }
    
    function free_result($id)
    {
        parent::free_result($id);
        return @pg_free_result($id);
    }
    
    function num_rows($id)
    {
        parent::num_rows($id);
        return pg_num_rows($id);
    }
    
    function num_fields($id)
    {
        parent::num_fields($id);
        return pg_num_fields($id);
    }

    function field_name($id, $num)
    {
        parent::field_name($id, $num);
        return pg_field_name($id, $num);
    }

    function insert_id()
    {
        die("This method does not work under PostgreSQL");
        // exceptions only work in php5
        //throw new FatalError("This method does not work under PostgreSQL");
    }

    function close()
    {
        parent::close();
        return pg_close($this->link_id);
    }
    
    
    function escape_string($string)
    {
        parent::escape_string($id);
        return pg_escape_string($string);
    }
    
    function error($message)
    {
        if ($this->debug)
        {
            $message = $this->error(pg_last_error($this->link_id));
        }
        parent::error($message);
    }
}

/**
 * The base Database class -- this must be extended.
 * <pre>
 *     $db = new db('localhost', 'root', 'mysupersecretpassword');
 *     $db->query_result("SELECT field FROM database WHERE name = %s", 'my name');
 * </pre>
 * @abstract
 */
class Database
{
    /**
     * Link ID
     * @var public
     */
    var $link_id;

    /**
     * Stores executed queries when debug is on.
     * @var public
     */
    var $queries = array();
    
    /**
     * Enables debug mode.
     * @var public
     */
    var $debug;

    /**
     * @var protected
     */
    var $__server;
    /**
     * @var protected
     */
    var $__user;
    /**
     * @var protected
     */
    var $__pass;
    /**
     * @var protected
     */
    var $__pconnect;
    /**
     * @var protected
     */
    var $__database;

    /**
     * Class constructor
     * <pre>
     *     $db = new db('localhost', 'root', 'mysupersecretpassword');
     * </pre>
     *
     * @param string $server MySQL host or path.
     * @param string $username Username.
     * @param string $password Password.
     * @param boolean $pconnect Use persistent connections.
     * @param string $database Database name.
     */
    function __construct($server, $username, $password='', $pconnect=false, $database='')
    {
        $this->__server = $server;
        $this->__username = $username;
        $this->__password = $password;
        $this->__pconnect = $pconnect;
        $this->__database = $database;
    }
    /**
     * Connect to the MySQL Server.
     *
     * @abstract
     * @return boolean
     */
    function connect($force=false)
    {
        if ($this->link_id && !$force) return true;
    }

    /**
     * Selects the Database
     *
     * @abstract
     * @param string $database
     * @return boolean
     */
    function select_db($database)
    {
        if (!$this->link_id) return false;
        
        if ($database == $this->__database) return true;
    }
    
    /**
     * @abstract
     */
    function execute($sql)
    {
        if (!$this->link_id)
            $this->connect();
    }

    /**
     * Queries the SQL server. Allows you to use sprintf-like
     * format and automatically escapes variables.
     * <pre>
     *    $db->query('SELECT %s FROM %s WHERE myfield = %s, 'field_name', 'table_name', 5);
     * </pre>
     *
     * @param string $string
     * @param {string | integer} $param1 first parameter
     * @param {string | integer} $param2 second parameter
     * @param {string | integer} $param3 ... 
     * @return unknown Resource ID
     */
    function query($string, $params=null)
    {
        if (!is_array($params))
        {
            $params = func_get_args();
            $params = array_slice($params, 1);
        }
        if (count($params))
        {
            foreach ($params as $key=>$value)
            {
                $params[$key] = $this->prepare_param($value);
            }
            $string = vsprintf($string, $params) or $this->error('Invalid sprintf: ' . $string ."\n".'Arguments: '. implode(', ', $params));
        }
        $timing = microtime(true);
        $id = $this->execute($string, $this->link_id);
        $timing = (int)((microtime(true)-$timing)*1000);

        $this->lastquery = $string;
        $this->queries[] = array($timing, $string);

        return $id;
    }
    
    /**
     * Internal handler for parameters. Returns an
     * escaped parameter.
     *
     * @param {string | integer} $param
     * @return {string | integer} Escaped parameter.
     */
    function prepare_param($param)
    {
        if ($param === null) return 'NULL';
        elseif (is_integer($param)) return $param;
        elseif (is_bool($param)) return $param ? 1 : 0;
        return "'".$this->escape_string($param)."'";
    }

    /**
     * Returns an array from the given Result ID
     *
     * @abstract
     * @param integer $id
     * @return unknown
     */
    function fetch_array($id) { }

    /**
     * Frees a Result from memory
     *
     * @param integer $id
     * @return unknown
     */
    function free_result($id) { }

    /**
     * Queries the SQL server, returning a single row
     *
     * @param string $string SQL Query.
     * @return unknown
     */
    function query_result($string)
    {
        $params = func_get_args();
        $id = call_user_func_array(array($this, 'query'), $params);
        $result = $this->fetch_array($id);
        $this->free_result($id);
        $this->lastquery = $string;
        return $result;
    }

    /**
     * Queries the SQL server, returning the defined (or first) select value
     * from the first row.
     *
     * @param string $string SQL Query.
     * @param string $value Optional select field name to return.
     * @return unknown
     */
    function query_result_single($string)
    {
        $params = func_get_args();
        $result = call_user_func_array(array($this, 'query_result'), $params);
        $this->free_result($id);
        $this->lastquery = $string;
        if (!$result) return false;
        return $result[0];
    }

    /**
     * Returns the number of rows
     *
     * @abstract
     * @param unknown $id
     * @return unknown
     */
    function num_rows($id) { }

    /**
     * Returns the number of fields
     *
     * @abstract
     * @param integer $id
     * @return unknown
     */
    function num_fields($id) { }

    /**
     * Returns the field name
     *
     * @abstract
     * @param integer $id
     * @param integer $num
     * @return unknown
     */
    function field_name($id, $num) { }

    /**
     * Returns the Row ID of the last inserted row
     *
     * @abstract
     * @return integer
     */
    function insert_id() { }

    /**
     * Close the connection
     *
     * @abstract
     * @return boolean
     */
    function close() { }

    /**
     * Runs mysql_escape_string to stop SQL injection
     *
     * @abstract
     * @param string $string
     * @return string
     */
    function escape_string($string) { }

    /**
     * Output the error
     *
     * @param string $string
     */
    function error($string)
    {
        if ($this->link_id)
        {
            $this->error_desc = mysql_error($this->link_id);
            $this->error_num = mysql_errno($this->link_id);
        }
        header('Content-Type: text/html');
        echo '<html><head><title>Database Error</title>';
        echo '<style type="text/css"><!--.error {font:11px tahoma,verdana,arial,sans-serif;}--></style></head>';
        echo '<body><blockquote>';
        echo '<p class="error">&nbsp;</p><p class=\"error\"><b>There seems to have been a slight problem with the database.</b><br />';
        echo 'Please try again by pressing the <a href="javascript:window.location=window.location;">refresh</a> button in your browser.</p>';
        echo '<p class="error">We apologize for any inconvenience.</p>';
        echo '<p class="error">Error Message: '.str_replace("\n", "<br />", htmlspecialchars($string)).'</p>';
        echo '</blockquote></body></html>';
        exit;
    }
}

?>
