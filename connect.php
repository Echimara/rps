<!-- Name: Chimara Okeke -->
<?php
    $credentials = "user=jqpublic password=Blu3Ski3s";
    $host   = "host=127.0.0.1";
    // The web server and database server are on the same machine; this wouldn't be
    // a good idea in a production setting.
    
    $port   = "port=5432";
    $dbname = "dbname=db55";
    
    // building connection argument string
    $connString = $host ." ". $dbname  ." ". $credentials;
    $dbConn = pg_connect("$connString"); // connect to Database
    
    if (!$dbConn)
    {
        die('Connection failed');
    }
    else
    {
        echo("Connection successful");
    }

    // Set the search path to 'rps'
    $result = pg_query($dbConn, "SET SEARCH_PATH TO rps;");
    if (!$result) 
    {
        echo "Set SEARCH_PATH failed.<br>";
    } 
    else 
    {
        echo "Search path set to 'rps'.<br>";
    }

    // Close database connection
    pg_close($dbConn)
    echo "Connection closed. <br>";
    
    // Wipe all of the strings to ensure we will send no information back.
    // A good practice with PHP
    unset($host);
    unset($port);
    unset($dbname);
    unset($credentials);
    unset($connString);
?>