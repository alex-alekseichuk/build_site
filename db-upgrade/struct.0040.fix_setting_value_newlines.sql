/* 
   some default_message_body settings have literal \n sequences in their values. 
   this should replace them with the actual newline characters. 
*/

update setting set att_val=replace(att_val,E'\\n',E'\n') where att_val like E'%\\\\%';


