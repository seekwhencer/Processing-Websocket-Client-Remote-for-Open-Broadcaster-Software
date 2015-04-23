<?php


    // edit the place where the fb php files are accessible
    // before you can fetch the comments:
    // create a fb app and get your app user access token,
    // edit the conf.php from the fb sources
    // and generate a long lived token with:
    //
    // fp.php?access_token=your acces token
    //
    $fbsdk_url = 'http://yourhost.xxx/your/path/'; // to the comments.php



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