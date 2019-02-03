module Back.Utils exposing (..)

import Task exposing (map, Task)
import Maybe exposing (withDefault)
import Board.File as File exposing(read, dict, fromDict, write)
import Board.Shared exposing (..)
import Dict exposing(Dict, insert, member, size)
import Board.Status exposing (..)
import Board.Internals exposing (..)


{-| Server state
-}
type alias State =
    Dict String String


{-| Save session to the disc
-}
saveSessions : ( State, a ) -> Task String a
saveSessions (state, res) =
    state 
        |> fromDict
        |> write "public/db.json"
        |> map (\ _ -> res)


{-| Load session from the disc
-}
getSession : b -> Request a -> State -> AnswerValue value state error
getSession param req state =
    let 
        sessionTag = 
            getSessionTag req state
        sessionValue = 
            Dict.get sessionTag state
    in
        withDefault "No value for your session" sessionValue
            |> makeStringResponse req
            |> Reply
        

{-| Path handler, save session to provided storage and return appropriate response 
-}
postSession : b -> Request String -> State -> ( State, AnswerValue a state error )
postSession param req state =
    let 
        sessionTag = 
            getSessionTag req state
    in
        case req.content of 
            Board.Shared.Data _ file ->    
                let 
                    newValue = file <| File.string File.ASCII
                in
                    (
                        insert sessionTag newValue state, 
                        newValue
                            |> makeStringResponse req 
                            |> addCookeis "session" sessionTag
                            |> Reply
                    )
            _ ->
                (
                    state,
                    Reply <| makeStringResponse req "something went wrong"
                )


{-| Extract existing session tag from state or create new one
-}    
getSessionTag : Request a -> State -> String
getSessionTag req state =
    case Dict.get "session" req.cookies of
        Just oldSessionTag ->
            oldSessionTag

        Nothing ->
            (Basics.toString req.time) ++ "-" ++ (Basics.toString <| size state)


{-| Add new cookei value to provided Response
-}
addCookeis : String -> String -> Response a -> Response a
addCookeis name value res =
    let 
        cookei = 
            { value = value
            , httpOnly = False
            , secure = False 
            , lifetime = Just <| 24*60*60*1000
            , domain = Nothing
            , path = Nothing
            }
    in
        { res 
        | cookeis = res.cookeis
            |> insert name cookei
        }


{-| Path handler, load file from disk in according to specified url
-}
getFile : String -> ( b, Request a ) -> Task String (AnswerValue value state error)
getFile path (param, req)  =
    let 
        res = getResponse req
        makeResponse file =
            { res
            | content = Data (File.getContentType path) file
            , id = req.id
            , status = ok
            } 
    in
        path
            |> read
            |> map makeResponse
            |> map Reply


{-| Construct Repsonse with a text body for provided Request and String
-}
makeStringResponse : Request a -> String -> Response b
makeStringResponse req text = 
    let 
        res = getResponse req
    in
        { res
        | content = Text "text/plain" text
        , id = req.id
        , status = ok
        } 