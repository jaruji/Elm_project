module Pages.Users exposing(..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
import Browser.Dom as Dom
import Task
import Http
import User
import Server
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)

{--
    This page shows the preview of all the registered users. The previews are paginated,
    meaning that only a fixed amount (max 20) previews will show per one page. This page also
    allows user to search other users based on their username. The search is dynamic, so on
    every onInput event in the searchbar, a HTTP request (Cmd Msg) will be sent. State of search
    will be lost if user leaves this page. The pagination doesn't use URL, it is realized entirely
    through the Model (page and query values).
--}

pageSize = 20

type alias Model =
  {  
    key: Nav.Key
    , status: Status
    , query: String
    , page: Int
  }

--status of query
type Status
  = Loading
  | Success (User.PreviewContainer)
  | Failure String

type Msg
  = Test
  | Response (Result Http.Error (User.PreviewContainer))
  | Query String
  | Empty
  | Jump Int

--we initially load all users (paginated!)
init: Nav.Key -> (Model, Cmd Msg)
init key =
    (Model key Loading "" 1, getUsers "" 1)


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Test ->
        (model, Cmd.none)

    Jump int ->
        --function that is used to jump to a different page of pagination.
        ({ model | page = int }, Cmd.batch [getUsers model.query int, Task.perform (\_ -> Empty) (Dom.setViewport 0 0)])

    Response response ->
        case response of
            Ok container ->
                --if we get a response, we store the user list in our state. If the list is empty
                --we count it as a failed query
                let
                    users = container.users
                in
                    if List.isEmpty users == True then
                        ({ model | status = Failure "Query returned no results" }, Cmd.none)
                    else
                        ({ model | status = Success container }, Cmd.none)
            Err log ->
                --if we get here, it means a connection error occured
                ({ model | status = Failure "Connection error"}, Cmd.none)

    Query query ->
        --function that is used to send a query to the server from input (onInput event)
        --we always go back to page 1 if we fiddle with input!
        ({ model | query = query, status = Loading, page = 1 }, getUsers query 1 )

    Empty ->
        --empty message that is used to move viewport to the top of the page.
        (model, Cmd.none)

view: Model -> Html Msg
view model =
    div[ class "container" ][
        h1[][ text "Check out all the registered users" ]
        , div [ class "form-group row", style "width" "70%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    input [ id "tw"
                    , type_ "text"
                    , class "form-control"
                    , placeholder "Search users"
                    , Html.Attributes.value model.query
                    , onInput Query ] []
                    , span[ style "color" "grey"
                    , class "glyphicon glyphicon-search form-control-feedback"
                    ][]
                ]
            ]
        ] 
        , hr [ style "margin-top" "-15px" ] []
        , case model.status of
            Loading ->
                div[][
                    h4[][ text "Sending the query..." ]
                    , Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
                ]
            Success container ->
                let
                    users = container.users
                in
                    div[][
                        div [ class "alert alert-success"
                        , style "margin" "auto"
                        , style "width" "60%"
                        , style "margin-bottom" "10px" ][
                            text ("Query returned " ++ String.fromInt(container.total) ++ " results") 
                        ]
                        , div[ class "panel panel-default"
                        , style "margin" "auto"
                        , style "border" "none" ]
                            --display user previews
                            (List.map User.showPreview users)
                        , div [ style "margin-top" "20px" ] [
                            --here we find out the number of buttons required to be displayed and display them
                            div [ style "width" "30%"
                            , style "margin" "auto" ] ((List.range 1 ( ceiling ( toFloat container.total / toFloat pageSize ))) |> List.map (viewButton model) )
                            , div [ class "help-block" ] [ text ( String.fromInt(model.page) ++ "/" ++ String.fromInt( ceiling ( toFloat container.total / toFloat pageSize ) ) )]
                        ]
                    ]
            Failure error ->
                div [ class "alert alert-warning"
                , style "margin" "auto"
                , style "width" "60%" ][
                    text error 
                ]
    ]

viewButton: Model -> Int -> Html Msg
viewButton model num =
    --button used to jump between pages of paginated output
    button[ class "btn btn-default"
    , if model.page == num then
        style "opacity" "0.3"
      else
        style "" ""
    , onClick (Jump num)
    ][
        text (String.fromInt num)
    ]

getUsers: String -> Int -> Cmd Msg
getUsers query page =
    --query to get paginated users from server
    Http.get
    { url = Server.url ++ "/accounts/paginate" ++ "?q=" ++ query
            ++ "&page=" ++ (String.fromInt page)
    , expect = Http.expectJson Response User.decodePreviewContainer
    }