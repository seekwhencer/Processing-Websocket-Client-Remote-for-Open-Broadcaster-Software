<?php

    $fbsdk_url = 'http://fb.seeekwhencer.de/';
    
    $fbsdk_url = 'http://localhost:8080/clients/fb.seekwhencer.de/';

    function fetch($url,$data){
        $ch = curl_init();  
        curl_setopt($ch, CURLOPT_URL,$url.'?'.$data);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER,true);
        curl_setopt($ch, CURLOPT_HEADER, false); 
        curl_setopt($ch, CURLOPT_POST, false);
        $output = curl_exec($ch);
        curl_close($ch);
        return $output;
    }

    if(!$_GET['object_id'] && !$_GET['access_token'])
        return;

    
    if($_GET['object_id']){
        $remote_url = $fbsdk_url.'comments.php';
        $getData = 'object_id='.$_GET['object_id'];
    }
    
    if($_GET['access_token']){
        $remote_url = $fbsdk_url.'token.php';
        $getData = 'access_token = '.$_GET['access_token'];
    }
    
    echo $get = fetch($remote_url,$getData);
    
    if($_GET['access_token']){
        $remote_url = $fbsdk_url.'longtoken.php';
        $getData = '';
        $get = fetch($remote_url,$getData);
    }

?>