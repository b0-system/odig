open Vcardgen
       
let () =
  let open Content_line in
  let open Vcard in
  let ( >@ ) a b = append_content_line a b in
  let open Name in
  let open Parameter in
  let open Value in
  let c = empty_vcard
          >@ (content_line FN [] (string_value "Vadim Zaliva"))
          >@ (content_line N [] (string_value "Zaliva; Vadim"))
          >@ (content_line EMAIL [
                             parameter "type" "INTERNET";
                             parameter "type" "WORK";
                             parameter "type" "pref";
                             parameter "PREF" "1"
                           ] (string_value "lord@codeminders.com"))
          >@ (content_line EMAIL [
                             parameter "type" "INTERNET";
                             parameter "type" "HOME";
                           ] (string_value "lord@crocodile.org")) in
  let cp = append_photo_from_file c "botero.jpeg" "JPEG" in
  print (output_string stdout) cp
  
        
