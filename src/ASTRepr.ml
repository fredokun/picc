
(* module ASTRepr 
   --------------

   AST Representation

*)

(** This module defines the implementation of the interfaces defined in Syntax *)

(* the AST Types are in the Syntax module *)

open Utils ;;
open Syntax ;;
open Types ;;
open TypeRepr ;;


(* Parent class of all the AST representation classes *)
(** Parent class of all the AST representations classes 
    contains the information generated by the parser *)
class virtual ast_repr = object
  val mutable sc = -1
  val mutable sl = -1
  val mutable ec = -1
  val mutable el = -1

  method startChar = sc
  method startLine = sl
  method endChar = ec
  method endLine = el

  method posString = 
    "from line " ^ (string_of_int sl) ^ " char " ^ (string_of_int sc) ^
      " to line " ^ (string_of_int el) ^ " char " ^ (string_of_int ec)
end

(** {2 Values representations } *)

(** Parent class of all the value representations *)
class value_repr v = object
  inherit ast_repr
  val mutable vtype = TUnknown

  method ofType = vtype
  method setType t = vtype <- t
end

(** Boolean representation of const_value_type *)
class bool_value_repr vt v = object
  inherit value_repr vt
  method toVal = v
  method toString = match v with
    | true -> "true"
    | false -> "false"
end
    
(** True value constructor *)
let makeVTrue () = VTrue (new bool_value_repr TBool true) ;;

(** False value constructor *)
let makeVFalse () = VFalse (new bool_value_repr TBool false) ;;

(** Integer representation of const_value_type *)
class int_value_repr vt v = object
  inherit value_repr vt
  method toVal = v
  method toString = string_of_int v
end

(** Integer value constructor *)
let makeVInt v = VInt (new int_value_repr TInt v) ;;


(** String representation of const_value_type *)
class string_value_repr vt (v:string) = object
  inherit value_repr vt
  method toVal = v
  method toString = "\"" ^ v ^ "\""
end

(** String value constructor *)
let makeVString v = VString (new string_value_repr TString v) ;;

(** Representation of 'a tuple_value_type *)
class tuple_value_repr vt (vs: value list) = object(self)
  inherit value_repr ((makeTupleTypeRepr vt) :> valueType tuple_type)
  method arity = (List.length vs)
  method types = match self#ofType with
    | TTuple t -> t#elements
    | _ -> failwith "wrong tuple type (please report)"
  method elements = vs
  method toString = string_of_collection "(" ")" "," string_of_value vs
end

(** Tuple representation constructor *)
let makeTupleRepr vt vs = new tuple_value_repr vt vs

(** Tuple value constructor *)
let makeTuple vt vs =
  VTuple ((makeTupleRepr vt vs):> value tuple_value_type )


(** Representation of variable_type *)
class variable_repr vt n = object
  inherit value_repr vt
  val mutable _index = -1
  val mutable _binder = None
  method name = n
  method index = _index
  method setIndex i = _index <- i
  method binder = _binder
  method setBinder (b:ast_binder_type) = _binder <- Some b
  (* classes implantant ast_binder_type:  
     in_action_repr
     new_action_repr
     let_action_repr
     definition_repr
 *)

  method toString = n ^ ":" ^ (string_of_valueType vt)
end

(** Variable value constructor *)
let makeVVar vt n =
  VVar (new variable_repr vt n)

(** Representation of 'a prim_valu_type *)
class prim_repr (mname:string) (pname:string) (ps:valueType list) (rt:valueType) (vs:value list) = object(self)
  inherit value_repr ((makePrimTypeRepr mname pname ps rt) :> ((valueType list),valueType) prim_type)
  method moduleName = mname
  method primName = pname
  method arity = List.length vs
  method args = vs
  method argTypes = match self#ofType with
    | TPrim t -> t#params
    | _ -> failwith "wrong primitive type (please report)"
  method toString = "#" ^ mname ^ ":" ^ pname ^ (string_of_collection "(" ")" "," string_of_value vs)
end

(** Variable value constructor *)
let makeVPrim mname pname ps rt vs = 
  VPrim (new prim_repr mname pname ps rt vs)

(** {2 Actions representations } *)

(** Representation of tau_action_type *)
class tau_action_repr = object
  inherit ast_repr
  method toString = "tau" 
end

(** Tau action constructor *)
let makeTau () = Tau (new tau_action_repr)  

(** Representation of out_action_type *)
class out_action_repr ch v vt = object
  inherit ast_repr
  val mutable _valueType = vt
  val mutable _channelIndex = -1
  val mutable _channelBinder = None
  method channel  = ch
  method channelIndex = _channelIndex
  method setChannelIndex i = _channelIndex <- i
  method channelType  = TChan vt
  method channelBinder = _channelBinder
  method setChannelBinder (b:ast_binder_type) = _channelBinder <- Some b
  method value = v
  method valueType = _valueType
  method toString = ch ^ "!" ^ (string_of_value v)
end

(** Output action constructor *)
let makeOutput ch v vt = Output (new out_action_repr ch v vt)

(** Representation of in_action_type *)
class in_action_repr (ch:string) (v:string) (vt:valueType) = object(self)
  inherit ast_repr
  val mutable _variableType = vt
  val mutable _channelIndex = -1
  val mutable _variableIndex = -1
  val mutable _channelBinder = None
  method channel  = ch
  method channelIndex = _channelIndex
  method setChannelIndex i = _channelIndex <- i
  method channelType  = TChan vt
  method channelBinder = _channelBinder
  method setChannelBinder (b:ast_binder_type) = _channelBinder <- Some b
  method fetchBinderType (b:string) = if b=self#variable then Some _variableType else None
  method variable = v
  method variableIndex = _variableIndex
  method setVariableIndex i = _variableIndex <- i
  method variableType = _variableType
  method toString = ch ^ "?(" ^ v ^ ")"
end

(** Input action constructor *)
let makeInput ch v vt = Input (new in_action_repr ch v vt)

(** Representation of new_action_type *)
class new_action_repr (v:string) (vt:valueType) = object(self)
  inherit ast_repr
  val mutable _variableType = vt
  val mutable _variableIndex = -1
  method variable = v
  method variableIndex = _variableIndex
  method setVariableIndex i = _variableIndex <- i
  method variableType = _variableType
  method fetchBinderType (b:string) = if b=self#variable then Some _variableType else None
  method toString = "new(" ^ v ^ ":" ^ (string_of_valueType _variableType) ^ ")"
end

(** New action constructor *)
let makeNew v vt = New (new new_action_repr v vt)

(** Representation of spawn_action_type *)
class spawn_action_repr (m:string) (d:string) (vts:valueType list) (vs:value list) = object
  inherit ast_repr
  val mutable _argTypes = vts
  method modName = m
  method defName = d
  method arity = List.length vs
  method args = vs
  method argTypes = _argTypes
  method toString = "spawn{" ^ m ^ ":" ^ d ^ (string_of_collection "(" ")" "," string_of_value vs) ^ "}"
end

(** Spawn action constructor *)
let makeSpawn m d vts vs = Spawn (new spawn_action_repr m d vts vs)

(** Representation of prim_action_type *)
class prim_action_repr (mname:string) (pname:string) (vts:valueType list) (vs:value list) = object
  inherit ast_repr
  val mutable _argTypes = vts
  method moduleName = mname
  method primName = pname
  method arity = List.length vs
  method args = vs
  method argTypes = _argTypes
  method toString = "#" ^ mname ^ ":" ^ pname ^ (string_of_collection "(" ")" "," string_of_value vs)
end

(*  [TODO] find some primitives examples, here is the syntax 
    that generates a call to makePrim :
    #moduleID:<ident>( values* ) 
    exemple (?):
    #println (cf stackless runtime environment p2)
*)
(** Primitive action constructor *)
let makePrim mname pname vts vs = Prim (new prim_action_repr mname pname vts vs)


(** Representation of let_action_type *)
class let_action_repr (v:string) (vt:valueType) (e:value) (et:valueType) = object(self)
  inherit ast_repr
  val mutable _variableType = vt
  val mutable _variableIndex = -1
  val mutable _valueType = et
  method variable = v
  method variableIndex = _variableIndex
  method setVariableIndex i = _variableIndex <- i
  method variableType = _variableType
  method value = e
  method valueType = _valueType
  method fetchBinderType (b:string) = if b=self#variable then Some _variableType else None
  method toString = "let(" ^ v ^ ":" ^ (string_of_valueType _variableType) ^ "=" ^ (string_of_value e) ^ ")"
end

(** Let action constructor *)
let makeLet var vartype e et = Let (new let_action_repr var vartype e et)

(** {2 Processes representations } *)

(** Parent class of all the processes representations*)
class virtual process_repr (m:string) (d:string) = object
  inherit ast_repr
  method inModule = m
  method inDef = d
end

(** Representation of term_process_type *)
class term_process_repr m d = object
  inherit process_repr m d
  method toString = "0"
end

let makeTerm m d = Term (new term_process_repr m d) ;;

(** Representation of call_process_type *)
class call_process_repr m d (mname:string) (dname:string) (vts : valueType list) (vs:value list) = object
  inherit process_repr m d
  val mutable _argTypes = vts
  method moduleName = mname
  method defName = dname
  method args = vs
  method arity = List.length vs
  method argTypes = _argTypes
  method setArgTypes vts = _argTypes <- vts
  method toString = mname ^ ":" ^ dname ^ (string_of_collection "(" ")" "," string_of_value vs)
end

let makeCall m d mname dname vts vs = Call (new call_process_repr m d mname dname vts vs)

let makeSpawnCall = function
  | Call c -> makeSpawn c#moduleName c#defName c#argTypes c#args
  | _ -> failwith "Not a call (please report)"

(** Representation of prefix_process_type *)
class prefix_process_repr (mname:string) (dname:string) (g:value) (gt:valueType) (a:action) (p:process) (i:int) = object
  inherit process_repr mname dname
  val mutable _guardType = gt
  method guard = g
  method guardType = _guardType
  method setGuardType gt = _guardType <- gt
  method action = a
  method continuation = p
  method index = i
  method toString = 
    (match g with | VTrue _ -> "" | _ -> "[" ^ (string_of_value g) ^ "] ")
  ^ (string_of_action a)
  ^ "," ^ (string_of_process p)
end

let makePrefixRepr m d g a p i = new prefix_process_repr m d g a p i

(** Representation of choice_process_type *)
class choice_process_repr m d (bs: (process prefix_process_type) list)  = 
  let ar = List.length bs 
  in object
    inherit process_repr m d
    method branches = bs
    method arity = ar
    method toString = 
      if ar=1 then (List.hd bs)#toString 
      else string_of_collection "" "" "+" (function x -> x#toString) bs
  end

let makeChoice m d bs =
  let rec makeBranches i bs = match bs with
    | [] -> []
    | (g,gt,a,p)::bs' -> (makePrefixRepr m d g gt a p i)::(makeBranches (i+1) bs')
  in Choice (new choice_process_repr m d (makeBranches 0 bs))

let makePrefix m d a p = makeChoice m d [ (makeVTrue (), TBool, a, p) ]

(** {2 Definitions representations } *)

class param_repr n t = object
  val mutable _type = t
  method name = n
  method ofType = _type
  method toString = n ^ ":" ^ (string_of_valueType t)
end

class definition_repr (n:string) (ps:(string * valueType) list)  (p:process) = 
  let ps' = List.map (fun (n,t) -> new param_repr n t) ps
  in
object
  inherit ast_repr
  val mutable _params = ps'
  val mutable _csize = -1
  val mutable _env = List.map fst ps
  method name = n
  method params = List.map (fun p -> (p#name, p#ofType)) _params
  method arity = List.length ps'
  method setParamTypes ps'' = _params <- List.map2 (fun p t -> new param_repr (p#name) t) _params ps''
  method env = _env
  method extendEnv v = _env <- _env @ [v]
  method lookupEnv v = let rec aux n vs = match vs with
    | [] -> None
    | u::vs' -> if v=u then Some n else aux (n + 1) vs'
                       in aux 0 _env
  method csize = _csize
  method esize = List.length _env
  method process = p
  method fetchBinderType (b:string) = let rec search = function
    | [] -> None
    | p::ps -> if b=p#name then Some p#ofType else search ps
                                      in search _params
  method toString = "def " ^ n ^ (string_of_collection "(" ")" "," (fun p -> p#toString) _params) ^ " = " ^ (string_of_process p)
end

let makeDefinition n ps p = Def (new definition_repr n ps p)

(* modules *)
(** {2 Modules representations } *)

class module_repr (n:string) (defs:definition list) = 
object
  inherit ast_repr
  val _definitions = Hashtbl.create (List.length defs)
  method name = n
  method definitions = Hashtbl.fold (fun n d defs -> d::defs) _definitions []
  method addDefinition (d:definition) = match d with | Def d' -> Hashtbl.add _definitions d'#name d
  method lookupDef (n:string) = Hashtbl.find _definitions n
  method toString = "module " ^ n ^ "\n" ^ (Hashtbl.fold (fun _ d str -> str ^ (string_of_definition d) ^ "\n") _definitions "")
  initializer List.iter (fun d -> match d with Def d' -> Hashtbl.add _definitions d'#name d) defs
end

let makeModule n defs = Module (new module_repr n defs)

