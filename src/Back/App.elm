port module Back.App exposing (..)

import Task exposing (map, andThen, succeed, onError, Task)
import Maybe exposing (withDefault)
import Board.File as File exposing(read, dict)
import Pathfinder exposing (..)
import Board exposing (..)
import Board.Router exposing (..)
import Board.Shared exposing (..)
import Dict exposing(Dict, insert, member, size)
import Board.Router.Static exposing (static)
import Board.Internals exposing (..)
import Json.Decode exposing (string)
import Back.Utils exposing (..)


{-| URL description for "/save" path
-}
savepath : URL
savepath =
    p "" </> p "save"


{-| URL description for "/public/db.json" path
-}
dbpath : String
dbpath =
    "./public/db.json"


{-| URL descriptions for "/save/local" and "/save/db" paths
-}
paths : { local : URL, db : URL }
paths =
    { local = savepath </> p "local"
    , db = savepath </> p "db"
    }


{-| Server configuration
-}
config : Configurations State
config = 
    { state = Dict.empty
    , errorPrefix = Just "Warning"
    , options = 
        { portNumber = 8085
        , timeout = 1000
        , https = Nothing
        }
    }
    

{-| Define port for subscription
-}
port subPort : (String -> msg) -> Sub msg


{-| Define server program
-}
main : Program Never State (Msg String State String)
main = board router config subPort


{-| Router describes relationships between paths and request handlers
-}
router : Request String -> Mode String (Answer String State String)
router =
    -- Defult router prints requests with specified prefix as default actions
    logger "Request"
        -- Synchronously handle GET request to "/save/local",
        -- check local state for a value based on session cookei
        |> getSyncState paths.local getSessionLocal
        -- Synchronously handle POST request to "/save/local",
        -- save value to local state based on session cookei
        |> postSyncState paths.local postSessionLocal
        -- Asynchronously handle GET request to "/save/db",
        -- check disk state for a value based on session cookei
        |> get paths.db getSessionDB
        -- Asynchronously handle POST request to "/save/db",
        -- save value to disk state based on session cookei
        |> post paths.db postSessionDB
        -- Asynchronously handle GET request to "/"
        -- Reply with "./public/index.html"
        |> get (p "/") getIndex
        -- statically serve files from "./public/"
        |> static (p "") "./public/"
        -- Asynchronously redirect "/index.html" to "/"
        |> get (p "/index.html") defaultRedirect
        -- Follback, match to any path, take entire unhandled address,
        -- Reply with a string value which specifies that the path does not exist
        |> getSync str getInvalid



{-| Path handler, query value session from local state based on cookei
-}
getSessionLocal : ( b , Request a) -> State -> ( State, AnswerValue value state error )
getSessionLocal (param, req) state =
    ( state 
    , getSession param req state
    )


{-| Path handler, query value session from db state based on cookei
-}
getSessionDB : ( b , Request a) -> Task x (AnswerValue value state error)
getSessionDB (param, req) = 
    readDict
        |> map (getSession param req)


{-| Path handler, update value for session at local state based on cookei
-}
postSessionLocal : ( b , Request String ) -> State -> ( State, AnswerValue value state error )
postSessionLocal (param, req) state =
    postSession param req state 


{-| Path handler, update value for session at db state based on cookei
-}
postSessionDB : ( b , Request String ) -> Task String (AnswerValue a state error)
postSessionDB (param, req)  =
    readDict
        |> map (postSession param req)
        |> andThen saveSessions


{-| Path handler, reply with "./public/index.html" value
-}
getIndex : ( b, Request a ) -> Task String (AnswerValue value state error)
getIndex =
    getFile "./public/index.html" 


{-| Path handler, asynchronously redirect to "/" path
-}
defaultRedirect : a -> Task.Task x (AnswerValue value model error)
defaultRedirect _ =
    "/"
        |> Redirect
        |> Task.succeed


{-| Path handler, exclude string from path and reply that it does not exist
-}
getInvalid : ( Params, Request a ) -> AnswerValue a state error
getInvalid (param, req) =
    case param of 
        StrParam url ->
            url ++ " does not exist"
                |> makeStringResponse req 
                |> Reply
        
        _ ->
            Next req
        

{-| Read from disc JSON file which pretends to be db
-}
readDict : Task x State
readDict =
    let
        replaceByEmptyDict _ =
            succeed Dict.empty
        passDictParser fun =
            fun <| dict string 
    in
        dbpath
            |> read
            |> map passDictParser
            |> onError replaceByEmptyDict
