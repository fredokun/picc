(* module TTests 
   -------------

   Tests of Typing module

*)
(** Various tests for the Typing module *)

open Types;;  
open TypeRepr;; 
open Syntax;; 
open ASTRepr;;

let env_printer def = 
  let def = definition_type_of_definition def in
  Printf.printf "%s env :[ %s ]\n " def#name (String.concat ", " def#env )


let ppstr2 = "def PingPong2(o:chan<string>,i:chan<string>,msg:string) = o!msg, i?(m), PingPong2(i,o,m)";;

let ppstr = "def PingPong(i:chan<string>,o:chan<string>,msg:string) =  i?(m), o!msg, PingPong(i,o,m)";;

let mainstr = "def Main() = new(c1:chan<string>),new(c2:chan<string>),spawn{PingPong(c1,c2,\"<PING>\")},spawn{PingPong2(c1,c2,\"<PONG>\")},end";;

let pp = ParseUtils.parseFromString ("module Test/PingPong \n" ^ ppstr ^ "\n" ^ ppstr2 ^ "\n" ^ mainstr) ;;

let check_pp () = Middleend.first_pass pp 2;;

check_pp ();;

env_printer (List.hd (module_type_of_module pp)#definitions);;
Printf.printf "\n\n";;
print_endline (string_of_module pp) ;;
