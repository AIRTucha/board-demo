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


savepath =
    p "" </> p "save"


dbpath =
    "./public/db.json"


paths =
    { local = savepath </> p "local"
    , db = savepath </> p "db"
    }


{-|
-}
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
type alias Model =
    Dict String String


{-|
-}
main = board router config suggestions


{-|
-}
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


getSessionLocal (param, req) model =
    ( model 
    , getSession param req model
    )


getSessionDB (param, req) = 
    readDict
        |> Task.map (getSession param req)


putSessionLocal (param, req) model =
    putSession param req model 


putSessionDB (param, req)  =
    readDict
        |> Task.map (putSession param req)
        |> Task.andThen saveSessions


{-|
-}
getIndex : ( b, Request a ) -> Task.Task String (AnswerValue value model error)
getIndex =
    getFile "./public/index.html" 


defaultRedirect _ =
    "/"
        |> Redirect
        |> Task.succeed


getStr (param, req) =
    case param of 
        StrParam url ->
            url ++ " does not exist"
                |> makeTextResponse req 
                |> Reply
        
        _ ->
            Next req
        

readDict =
    dbpath
        |> read
        |> Task.map (\ f ->  f <| dict Json.Decode.string)
        |> Task.onError (\ err -> Task.succeed Dict.empty)
