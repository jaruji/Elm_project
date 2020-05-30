module Pages.Tags exposing (..)

import Browser.Navigation as Nav
import Browser.Dom as Dom
import Task
import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Image
import Server
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Tag
import Query
import Time

{--
    This page displays paginated output of images that fit the query - the query being a
    string representing a tag, that the images contain. In this file, we use Session Storage
    to store the state so that we can restore it even after leaving this page. This approach is
    useful for saving and restoring essentially any state within the single page app.
--}

--9 images per page
pageSize = 9

type alias Model =
  {
    query: String
    , status: Status
    , page: Int
  }

type Msg
  = Empty
  | Query String
  | Response (Result Http.Error(Image.PreviewContainer))
  | Jump Int
  --Restoring state receives Maybe Encode.Value - maybe the json is in session storage, if
  --it isn't we simply receive Nothing
  | Restore (Maybe Encode.Value)
  | Request

type Status
  = Loading
  | Success (Image.PreviewContainer)
  | Failure String

init: Nav.Key -> Maybe String -> (Model, Cmd Msg)
init key query =
    case query of
        Just q ->
            --if a query is encoded in URL, paste it into the search bar and send query to server
            (Model q Loading 1, Cmd.batch[ Task.perform (\_ -> Empty) (Dom.setViewport 0 0), getImages q 1, Query.saveState (Query.encode q 1) ])
        Nothing ->
            --otherwise dont send anyting to server and try to restore the state from Session Storage
            (Model "" Loading 1, Cmd.batch[ Task.perform (\_ -> Request) (Dom.setViewport 0 0) ])

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
            (model, Cmd.none)

        Request ->
            --send a request to JavaScript that initiates the restoring of stored state
            (model, Query.request ())

        Jump int ->
            --switching between pages of paginated output, we need to update the state in session
            --storage with the new page value
            if model.query == "" then
                ({ model | page = int, status = Loading }, Cmd.none)
            else
                ({ model | page = int }
                , Cmd.batch [ getImages model.query int
                , Task.perform (\_ -> Empty) (Dom.setViewport 0 0) 
                , Query.saveState (Query.encode model.query int) 
                ])
        Query string ->
            --querying the server, we also need to store the query in session storage so it can be restored later
            if string == "" then
                --delete the session storage entry if query is empty - no point in storing this
                ({ model | query = string, status = Loading, page = 1 }, Query.saveState (Query.encode string model.page))
            else
                ({ model | query = string, page = 1 }, Cmd.batch[ getImages string model.page, Query.saveState (Query.encode string model.page) ])

        Response response ->
            case response of
                Ok container ->
                    ({ model | status = Success container }, Cmd.none)
                Err log ->
                    ({ model | status = Failure "Connection error" }, Cmd.none)
        
        Restore value ->
            --message used for restoring stored state
            case value of
                Nothing ->
                    --if restored value is Nothing, session storage was empty
                    (model, Cmd.none)
                Just json ->
                    --otherwise we decode the entry and use it to restore our page state
                    let
                        query = Query.decodeQuery json
                        page = Query.decodePage json
                    in
                    ({ model | query = query
                    , page = page
                    }, Cmd.batch[ getImages query page, Query.saveState (Query.encode query page) ])

view: Model -> Html Msg
view model =
    div[][
        h1[][ text "Search images based on tags" ]
        , div [ class "help-block" ][ text "The search is not case sensitive" ]
        , div [ class "form-group row", style "width" "70%", style "margin" "auto", style "padding-bottom" "15px" ][ 
            div [ class "col-md-offset-2 col-md-8" ][
                div[ class "form-group has-feedback" ][
                    input [ type_ "text"
                    , class "form-control"
                    , placeholder "Search tags"
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
                text ""
            Success container ->
                let
                    images = container.images
                in
                case List.length images of
                    0 ->
                        div [ class "alert alert-warning"
                        , style "margin" "auto"
                        , style "width" "60%" ][
                            text ("No results for tag ")
                            , Tag.view model.query
                        ]
                    _ ->
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
                                (List.map Image.showPreview images)
                            , div [ style "margin-top" "20px" ] [
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
    button[ class "btn btn-default"
    , if model.page == num then
        style "opacity" "0.3"
      else
        style "" ""
    , onClick (Jump num)
    ][
        text (String.fromInt num)
    ]

getImages: String -> Int -> Cmd Msg
getImages query page =
    Http.get
    { url = Server.url ++ "/tags" ++ "?q=" ++ query 
            ++ "&page=" ++ (String.fromInt page) 
    , expect = Http.expectJson Response Image.decodePreviewContainer
    }

subscriptions: Model -> Sub Msg
subscriptions model =
    --we must be subscribed to the Restore function so we will get the Maybe Encode.Value when
    --it will be sent our way
    Query.restoreState Restore
