module Back.Utils exposing (..)

import Task
import Maybe exposing (withDefault)
import Board.File as File exposing(read, dict)
import Board.Shared exposing (..)
import Dict exposing(Dict, insert, member, size)
import Board.Status exposing (..)
import Board.Internals exposing (..)


{-|
-}
saveSessions (model, res) =
    model 
        |> File.fromDict
        |> File.write "public/db.json"
        |> Task.map (\ _ -> res)


{-|
-}
getSession param req model =
    let 
        sessionTag = 
            getSessionTag req model
        sessionValue = 
            Dict.get sessionTag model
    in
        (withDefault "No value for your session" sessionValue)
            |> makeTextResponse req
            |> Reply
        

{-|
-}
putSession param req model =
    let 
        sessionTag = 
            getSessionTag req model
    in
        case req.content of 
            Board.Shared.Data _ file ->    
                let 
                    newValue = file <| File.string File.ASCII
                in
                    (
                        insert sessionTag newValue model, 
                        newValue
                            |> makeTextResponse req 
                            |> addCookeis "session" sessionTag
                            |> Reply
                    )
            _ ->
                (
                    model,
                    Reply <| makeTextResponse req "something went wrong"
                )


{-|
-}    
getSessionTag req model =
    case Dict.get "session" req.cookies of
        Just oldSessionTag ->
            oldSessionTag

        Nothing ->
            (Basics.toString req.time) ++ "-" ++ (Basics.toString <| size model)


{-|
-}
addCookeis name value res =
    let 
        cookei str = 
            { value = str
            , httpOnly = False
            , secure = False 
            , lifetime = Just <| 24*60*60*1000
            , domain = Nothing
            , path = Nothing
            }
    in
        { res 
        | cookeis = res.cookeis
            |> insert name (cookei value) 
        }


{-|
-}
getFile : String -> ( b, Request a ) -> Task.Task String (AnswerValue value model error)
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
            |> Task.map makeResponse
            |> Task.map Reply


{-|
-}
makeTextResponse req text = 
    let 
        res = getResponse req
    in
        { res
        | content = Text "text/plain" text
        , id = req.id
        , status = ok
        } 