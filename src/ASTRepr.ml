(* module ASTRepr 
   --------------

   AST Representation

*)
(** This module defines the implementation of the interfaces defined in Syntax *)

open Utils;;
open Syntax;;
open Types;;
open TypeRepr;;

(** parent class of all the AST representations classes, contains the information generated by the parser *)
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

(** parent class of all the Syntax.valueType representations *)
class value_repr v = object
  inherit ast_repr
  val mutable _vtype = TUnknown

  method ofType = _vtype
  method setType t = _vtype <- t 
end

(** boolean representation of Syntax.const_value_type *)
class bool_value_repr vt v = object
  inherit value_repr vt
  
  method toVal = v
  method toString =
    match v with
      | true -> "true"
      | false -> "false"
end
    
(** constructor boolean value true *)
let makeVTrue () = VTrue (new bool_value_repr TBool true);;

(** constructor boolea value false *)
let makeVFalse () = VFalse (new bool_value_repr TBool false);;

(** integer representation of Syntax.const_value_type *)
class int_value_repr vt v = object
  inherit value_repr vt
  method toVal = v
  method toString = string_of_int v
end

(** constructor integer value *)
let makeVInt v = VInt (new int_value_repr TInt v);;

(** string representation of Syntax.const_value_type *)
class string_value_repr vt (v : string) = object
  inherit value_repr vt
  
  method toVal = v
  method toString = "\"" ^ v ^ "\""
end

(** constructor string value *)
let makeVString v = VString (new string_value_repr TString v);;

(** representation of Syntax.tuple_value_type *)
class tuple_value_repr (vt : valueType list) (vs : value list) = object(self)
  inherit value_repr ((makeTupleTypeRepr vt) :> valueType tuple_type)
  val mutable _els = vs
  val mutable _vts = vt
    
  method arity = List.length vs
  method types =
    match self#ofType with
      | TTuple (t) -> t#els
      | _ -> failwith "wrong tuple type, please report (maybe tuple type has not been setted)"
  method setTypes ts =
    match self#ofType with
      | TTuple (t) -> t#setEls ts
      | _ -> failwith "wrong tuple type"
  method elements = vs
  method toString = (string_of_collection "(" ")" "," string_of_value self#elements) ^ " of types : " ^ (string_of_collection "(" ")" "," string_of_valueType self#types) 
  initializer self#setType (TTuple (TypeRepr.makeTupleTypeRepr vt))
end

(** constructor tuple *)
let makeTupleRepr vt vs = new tuple_value_repr vt vs;;

(** tuple value constructor *)
let makeTuple vt vs = VTuple ((makeTupleRepr vt vs) :> value tuple_value_type);;

(** representation of Syntax.variable_type *)
class variable_repr vt n = object(self)
  inherit value_repr vt
  val mutable _index = -1
  val mutable _binder = None
 
  method name = n
  method index = _index
  method setIndex i = _index <- i
  method binder = _binder
  method setBinder (b : ast_binder_type) = _binder <- Some b
  method toString = n ^ ":" ^ (string_of_valueType self#ofType)
end

(** constructor variable value *)
let makeVVar vt n = VVar (new variable_repr vt n);;

(** representation of Syntax.prim_value_type *)
class prim_repr (mname : string) (pname : string) (ps : valueType list) (rt : valueType) (vs : value list) = object(self)
  inherit value_repr ((makePrimTypeRepr mname pname ps rt) :> ((valueType list), valueType) prim_type)
  val mutable _returnType = rt
  
  method moduleName = mname
  method primName = pname
  method arity = List.length vs
  method args = vs
  method argTypes =
    match self#ofType with
      | TPrim (t) -> t#params
      | _ -> failwith "wrong primitive type (please report)"
  method setArgTypes ts =
    match self#ofType with
      | TPrim (t) -> t#setParams ts
      | _ -> failwith "wrong primitive type"
  method toString = "#" ^ mname ^ ":" ^ pname ^ (string_of_collection "(" ")" "," string_of_value vs)
  method returnType = _returnType
  method setReturnType t = _returnType <- t
  initializer self#setType (TPrim (TypeRepr.makePrimTypeRepr mname pname ps rt))
end

(** constructor primitive *)
let makeVPrim mname pname ps rt vs = VPrim (new prim_repr mname pname ps rt vs);;

(** {2 Actions representations } *)

(** Representation of Syntax.out_action_type *)
class out_action_repr ch v vt = object
  inherit ast_repr
  val mutable _channelIndex = -1
  val mutable _channelBinder = None
  val mutable _channelType = TChan (vt)
  val mutable _valueType = vt
  
  method channel = ch
  method channelType = _channelType
  method setChannelType t = _channelType <- t
  method channelIndex = _channelIndex
  method setChannelIndex i = _channelIndex <- i
  method channelBinder = _channelBinder
  method setChannelBinder (b : ast_binder_type) = _channelBinder <- Some (b)
  method value = v
  method valueType = _valueType
  method setValueType t = _valueType <- t
  method toString = ch ^ "!" ^ (string_of_value v)
end

(** constructor Output action *)
let makeOutput ch v vt = Output (new out_action_repr ch v vt);;

(** representation of Syntax.in_action_type *)
class in_action_repr (ch : string) (v : string) (vt : valueType) = object(self)
  inherit ast_repr
  val mutable _channelType = TChan (vt)
  val mutable _variableType = vt
  val mutable _channelIndex = -1
  val mutable _variableIndex = -1
  val mutable _channelBinder = None
  
  method channel = ch
  method channelType = _channelType
  method setChannelType t = _channelType <- t
  method channelIndex = _channelIndex
  method setChannelIndex i = _channelIndex <- i
  method channelBinder = _channelBinder
  method setChannelBinder (b : ast_binder_type) = _channelBinder <- Some (b)
  method variable = v
  method variableType = _variableType
  method setVariableType t = _variableType <- t
  method variableIndex = _variableIndex
  method setVariableIndex i = _variableIndex <- i
  method fetchBinderType (b : string) = if b = self#variable then Some _variableType else None
  method toString = ch ^ "?(" ^ v ^ ":" ^ (string_of_valueType _variableType) ^ ")"
end

(** constructor Input action *)
let makeInput ch v vt = Input (new in_action_repr ch v vt);;

(** representation of Syntax.tau_action_type *)
class tau_action_repr = object
  inherit ast_repr
  
  method toString = "tau" 
end

(** constructor Tau action *)
let makeTau () = Tau (new tau_action_repr);; 

(** representation of Syntax.new_action_type *)
class new_action_repr (v : string) (vt : valueType) = object(self)
  inherit ast_repr
  val mutable _variableType = vt
  val mutable _variableIndex = -1
  val mutable _channelBinder = None
 
  method variable = v
  method variableType = _variableType
  method variableIndex = _variableIndex
  method setVariableIndex i = _variableIndex <- i
  method setChannelBinder (b : ast_binder_type) = _channelBinder <- Some (b)
  method fetchBinderType (b : string) = if b = self#variable then Some _variableType else None
  method toString = "new(" ^ v ^ ":" ^ (string_of_valueType _variableType) ^ ")"
end

(** constructor New action *)
let makeNew v vt = New (new new_action_repr v vt);;

(** representation of Syntax.spawn_action_type *)
class spawn_action_repr (m : string) (d : string) (vts : valueType list) (vs : value list) = object
  inherit ast_repr
  val mutable _argTypes = vts
  
  method moduleName = m
  method defName = d
  method arity = List.length vs
  method args = vs
  method argTypes = _argTypes
  method setArgTypes vt = _argTypes <- vt
  method toString = "spawn{" ^ m ^ ":" ^ d ^ (string_of_collection "(" ")" "," string_of_value vs) ^ "}"
end

(** constructor Spawn action *)
let makeSpawn m d vts vs = Spawn(new spawn_action_repr m d vts vs);;

(** representation of Syntax.prim_action_type *)
class prim_action_repr (mname : string) (pname : string) (vts : valueType list) (vs : value list) = object
  inherit ast_repr
  val mutable _argTypes = vts
  
  method moduleName = mname
  method primName = pname
  method arity = List.length vs
  method args = vs
  method argTypes = _argTypes
  method setArgTypes v = _argTypes <- v
  method toString = "#" ^ mname ^ ":" ^ pname ^ (string_of_collection "(" ")" "," string_of_value vs)
end

(** constructor Primitive action *)
let makePrim mname pname vts vs = Prim (new prim_action_repr mname pname vts vs);;

(** representation of Syntax.let_action_type *)
class let_action_repr (v : string) (vt : valueType) (e : value) (et : valueType) = object(self)
  inherit ast_repr
  val mutable _variableType = vt
  val mutable _variableIndex = -1
  val mutable _valueType = et
  
  method variable = v
  method variableType = _variableType
  method variableIndex = _variableIndex
  method setVariableIndex i = _variableIndex <- i
  method fetchBinderType (b : string) = if b = self#variable then Some _variableType else None
  method value = e
  method valueType = _valueType
  method setValueType t = _valueType <- t
  method toString = "let(" ^ v ^ ":" ^ (string_of_valueType _variableType) ^ "=" ^ (string_of_value e) ^ ")"
end

(** constructor Let action *)
let makeLet var vartype e et = Let (new let_action_repr var vartype e et);;

(** {2 Processes representations } *)

(** parent class of all the processes representations*)
class virtual process_repr (m : string) (d : string) = object
  inherit ast_repr
  
  method inModule = m
  method inDef = d
end

(** representation of Syntax.term_process_type *)
class term_process_repr m d = object
  inherit process_repr m d

  method toString = "0"
end

(** constructor Term process *)
let makeTerm m d = Term (new term_process_repr m d);;

(** epresentation of Syntax.call_process_type *)
class call_process_repr m d (mname : string) (dname : string) (vts : valueType list) (vs : value list) = object
  inherit process_repr m d
  val mutable _argTypes = vts
  
  method moduleName = mname
  method defName = dname
  method args = vs
  method arity = List.length vs
  method argTypes = _argTypes
  method setArgTypes vts = _argTypes <- vts
  method toString = mname ^ ":" ^ dname ^ (string_of_collection "(" ")" "," string_of_value vs) ^ (string_of_collection "r" "r" "," string_of_valueType vts)
end

(** constructor Call process *)
let makeCall m d mname dname vts vs = Call (new call_process_repr m d mname dname vts vs);;

(** constructor helper: build a spawn on the Call argument *)
let makeSpawnCall = function
  | Call c -> makeSpawn c#moduleName c#defName c#argTypes c#args
  | _ -> failwith "Not a call (please report)"

(** representation of Syntax.prefix_process_type *)
class prefix_process_repr (mname : string) (dname : string) (g : value) (gt : valueType) (a : action) (p : process) (i : int) = object
  inherit process_repr mname dname
  val mutable _guardType = gt
  
  method guard = g
  method guardType = _guardType
  method setGuardType gt = _guardType <- gt
  method action = a
  method continuation = p
  method index = i
  method toString = 
    (match g with
       | VTrue _ -> ""
       | _ -> "[" ^ (string_of_value g) ^ "] ")
    ^ (string_of_action a) ^ "," ^ (string_of_process p)
end

(** constructor Prefix process *)
let makePrefixRepr m d g a p i = new prefix_process_repr m d g a p i;;

(** representation of Syntax.choice_process_type *)
class choice_process_repr m d (bs : (process prefix_process_type) list) = 
  let ar = List.length bs in
object
  inherit process_repr m d
  
  method branches = bs
  method arity = ar
  method toString = 
    if(ar = 1)then
      (List.hd bs)#toString 
    else
      string_of_collection "" "" "+" (function x -> x#toString) bs
end
    
(** constructor Choice process *)
let makeChoice m d bs =
  let rec makeBranches i bs =
    match bs with
      | [] -> []
      | (g, gt, a, p)::bs' -> (makePrefixRepr m d g gt a p i)::(makeBranches (i + 1) bs')
  in
    Choice (new choice_process_repr m d (makeBranches 0 bs))

(** constructor 1 branch Choice process *)
let makePrefix m d a p = makeChoice m d [(makeVTrue (), TBool, a, p)]

(** {2 Definitions representations } *)

(** representation of a parameter used in Syntax.definition_repr *)
class param_repr n t = object
  val mutable _type = t
    
  method name = n
  method ofType = _type
  method toString = n ^ ":" ^ (string_of_valueType t)
end
  
(** representation of Syntax.definition_type *)
class definition_repr (n : string) (ps : (string * valueType) list) (p : process) = 
  let ps' = List.map (fun (n, t) -> new param_repr n t) ps in
object
  inherit ast_repr
  val mutable _params = ps'
  val mutable _env = List.map fst ps
  val mutable _csize = -1
  val mutable _esize = -1
  val mutable _nbchans = -1
  val mutable _nbchoice = -1

  method name = n
  method params = List.map (fun p -> (p#name, p#ofType)) _params
  method arity = List.length ps'
  method setParamTypes ps'' = _params <- List.map2 (fun p t -> new param_repr (p#name) t) _params ps''
  method env = _env
  method extendEnv v = _env <- _env @ [v]
  method lookupEnv v =
    let rec aux n vs =
      match vs with
	| [] -> None
	| u::vs' -> if v=u then Some n else aux (n + 1) vs'
    in
      aux 0 _env
  method csize = _csize
  method setCsize c = _csize <- c
  method esize = _esize
  method setEsize e = _esize <- e
  method nbChannels = _nbchans
  method setNbChannels c = _nbchans <- c
  method nbChoiceMax = _nbchoice
  method setNbChoiceMax c = _nbchoice <- c
  method process = p
  method fetchBinderType (b:string) =
    let rec search = function
      | [] -> None
      | p::ps ->
	  if b = p#name then
	    Some p#ofType
	  else
	    search ps
    in
      search _params
  method toString =
    "def " ^ n ^ (string_of_collection "(" ")" "," (fun p -> p#toString) _params) ^ " = " ^ (string_of_process p)
end

(** constructor Definition *)
let makeDefinition n ps p = Def (new definition_repr n ps p);;

(** {2 Modules representations } *)

(** representation of Syntax.module_type *)
class module_repr (n : string) (defs : definition list) = object
  inherit ast_repr
  val _definitions = Hashtbl.create (List.length defs)
    
  method name = n
  method definitions = Hashtbl.fold (fun n d defs -> d::defs) _definitions []
  method addDefinition (d : definition) =
    match d with
      | Def d' -> Hashtbl.add _definitions d'#name d
  method lookupDef (n : string) = Hashtbl.find _definitions n
  method toString =
    "module " ^ n ^ "\n" ^ (Hashtbl.fold (fun _ d str -> str ^ (string_of_definition d) ^ "\n") _definitions "")
  initializer List.iter (fun d -> match d with Def d' -> Hashtbl.add _definitions d'#name d) defs
end

(** constructor Module *)
let makeModule n defs = Module (new module_repr n defs);;

