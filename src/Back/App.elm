port module Back.App exposing (..)

import Task
import Maybe exposing (withDefault)
import Board.File as File exposing(read, dict)
import Pathfinder exposing (..)
import Board exposing (..)
import Board.Router exposing (..)
import Board.Shared exposing (..)
import Dict exposing(Dict, insert, member, size)
import Board.Router.Static exposing (static)
import Board.Internals exposing (..)
import Json.Decode
import Back.Utils exposing (..)


{-|
-}
savepath : URL
savepath =
    p "" </> p "save"


{-|
-}
dbpath : String
dbpath =
    "./public/db.json"


{-|
-}
paths : { local : URL, db : URL }
paths =
    { local = savepath </> p "local"
    , db = savepath </> p "db"
    }


{-|
-}
config : Configurations Model
config = 
    { state = Dict.empty
    , errorPrefix = Just "Warning"
    , options = 
        { portNumber = 8085
        , timeout = 1000
        , https = Nothing
        }
    }
    

{-|
-}
port suggestions : (String -> msg) -> Sub msg


{-|
-}
main : Program Never Model (Msg String Model String)
main = board router config suggestions


{-|
-}
router : Request String -> Mode String (Answer String Model String)
router =
    logger "Request"
        |> getSyncState paths.local getSessionLocal
        |> postSyncState paths.local putSessionLocal
        |> get paths.db getSessionDB
        |> post paths.db putSessionDB
        |> get (p "/") getIndex
        |> static (p "") "./public/"
        |> get (p "/index") defaultRedirect
        |> get (p "/index.html") defaultRedirect
        |> getSync str getStr


{-|
-}
getSessionLocal : ( b , Request a) -> Model -> ( Model, AnswerValue value model error )
getSessionLocal (param, req) model =
    ( model 
    , getSession param req model
    )


{-|
-}
getSessionDB : ( b , Request a) -> Task.Task x (AnswerValue value model error)
getSessionDB (param, req) = 
    readDict
        |> Task.map (getSession param req)


{-|
-}
putSessionLocal : ( b , Request String ) -> Model -> ( Model, AnswerValue value model error )
putSessionLocal (param, req) model =
    putSession param req model 


{-|
-}
putSessionDB : ( b , Request String ) -> Task.Task String (AnswerValue a model error)
putSessionDB (param, req)  =
    readDict
        |> Task.map (putSession param req)
        |> Task.andThen saveSessions


{-|
-}
getIndex : ( b, Request a ) -> Task.Task String (AnswerValue value model error)
getIndex =
    getFile "./public/index.html" 


{-|
-}
defaultRedirect : a -> Task.Task x (AnswerValue value model error)
defaultRedirect _ =
    "/"
        |> Redirect
        |> Task.succeed


{-|
-}
getStr : ( Params, Request a ) -> AnswerValue a model error
getStr (param, req) =
    case param of 
        StrParam url ->
            url ++ " does not exist"
                |> makeTextResponse req 
                |> Reply
        
        _ ->
            Next req
        

{-|
-}
readDict : Task.Task x Model
readDict =
    dbpath
        |> read
        |> Task.map (\ f ->  f <| dict Json.Decode.string)
        |> Task.onError (\ err -> Task.succeed Dict.empty)
