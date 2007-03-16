<?php

function perl_bytea_unescape_char($matches){
  $match = substr($matches[0],1);
  if($match=='\\'){
    return '\\';
  }else{
    return chr(octdec($match));
  }
}

function perl_bytea_unescape($raw){
  return preg_replace_callback("/\\\\{2}|\\\\\d{3}/","perl_bytea_unescape_char",$raw);
}

function filename($fielddata){
  $space = strpos($fielddata," ");
  $filename = substr($fielddata,0,$space);
  return $filename;
}

function mimetype($fielddata){
  $space = strpos($fielddata," ");
  $hash = strpos($fielddata,"#");
  $mimetype = substr($fielddata,$space,$hash-$space);
  return $mimetype;
}

function rawdata($fielddata){
  $hash = strpos($fielddata,"#");	
  $raw=substr($fielddata,$hash+1);	
  return $raw;
}

/* you have just selected something from a table
with gedafe encoded files in a bytea column 
the data that came from that column is now in
$bytea_field_contents. This data both needs to be
unescaped and decoded into usable parts.
*/ 


$unescaped_data = perl_bytea_unescape($bytea_field_contents);
$original_mimetype = mimetype($unescaped_data);
$original_filename = filename($unescaped_data);
$original_file_contents = rawdata($unescaped_data);

// these are the fields that you can use.

?>