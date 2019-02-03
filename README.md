# Demo Example application based on Elm 0.18 and Board framework 

Full-stack Demo Example application on Elm and [Board](github.com/AIRTucha/board). It showcases the key functionality required from modern SAP.

## Back-end

Nowadays, back-end applications are mainly used for aggregation and processing of the data from various number of resources: server state, database, third party API and local memory. The system should be able to request the data and save it back. The data sources can be divided into two categories: synchronous and asynchronous ones. The example is focused on demonstration how to handle both of the situations.

The server is described at *./src/Back/App.elm* and *./src/Back/Utils.elm*. *Utils* file contains a general purpose functions which are used at *App* file to implement the server logic. *App* has static configuration values, *router* and functions which are responsible for handling of input requests.

*Router* establish correspondence between requests' path and appropriate handler. It implements following API:

- requests to "/save/local" 
    - POST saves string value for the session at the server state 
    - GET return stored value for the session
- requests to "/save/db" 
    - POST saves string value for the session at the JSON file which pretends to be db
    - GET return stored at db value for the session 
- GET request to "/" returns *./public/index.html*
- servers any static files from *./public/*, move to next handler if there is no matching path
- GET request to "/index" is redirect to "/"
- GET to any unexpected path is replied with an information that the path does not exists. The address is extracted from url and passed as param argument to path handler function.

```elm
router : Request String -> Mode String (Answer String State String)
router =
    -- Default router prints requests with specified prefix as default actions
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
        |> static any "./public/"
        -- Asynchronously redirect "/index" to "/"
        |> get (p "/index") (\ _ -> succeed << Redirect <| "/")
        -- Fallback, match to any path, take entire unhandled address,
        -- Reply with a string value which specifies that the path does not exist
        |> getSync str getInvalid   
```

The application runs on top of Node.js and it is booted by *./local.js*.

[Board Seed project ](github.com/AIRTucha/board-seed) can be used to quickly bootstrap your own server.

## Front-end

The front-end is described at *./src/Front/App.elm* and *./src/Front/Utils.elm*. *Utils* file contains a general purpose functions and static configurations which are used at *App* file to implement the logic of application UI. 

*App* file is a very simple Elm application. It has *main* bootstrap functions which init and describe the app. The function forces rendering with initial placeholder data and makes asynchronous requests to get state from server. It also wires up view and update functions. *update* function handles five types of events which can possible accrue during life circle of the system. It process clients input, requests and responses to the back-end. The last part of the program is *view* which utilizes *makeRow* function from *Utils* to create the row components which manages clients input and triggers server communication.

The application is loaded by *./public/index.html*.

More complex Elm applications can be found at official Elm documentation.

# Development instructions

The project is powered by *npm* and *Node.js*. 

For installation of dependencies run:

    npm install

For installation of only *Elm* dependencies run: 

    npm run install

For building of back-end application to *./dist/app.js* run:

    npm run back

For building of front-end application to *./public/app.js* run:

    npm run front

For building of entire application with watch run:

    npm start