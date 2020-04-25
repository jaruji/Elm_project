module Pages.Gallery exposing (..)

import Browser
import Browser.Navigation as Nav
import Browser.Dom as Dom
import Url.Builder as Url
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, field, string)
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import FeatherIcons as Icons
import Task
import User
import Image
import Server

pageSize = 9

type alias Model = 
  {
    status: Status
    , page: Int
    , key: Nav.Key
    , sort: String
  }

type Status
    = Loading
    | Failure
    | Success (Image.PreviewContainer)

type Msg
    = Response (Result Http.Error (Image.PreviewContainer))
    | SortNewest
    | SortPopular
    | SortTop
    | Empty
    | Jump String Int



init :  Maybe User.Model -> Nav.Key -> Maybe Int -> Maybe String -> (Model, Cmd Msg)
init user key page sort =
  case page of
    Just int ->
      case sort of
        Just string ->
          (Model Loading int key string, get string int)
        _ ->
          (Model Loading int key "newest", get "newest" int)

    Nothing ->
      ( Model Loading 1 key "newest", get "newest" 1)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
          (model, Cmd.none)

        Response response ->
            case response of
                Ok imageUrl ->
                    ({ model | status = Success imageUrl }, Cmd.none )

                Err _ ->
                    ({ model | status = Failure }, Cmd.none )

        SortNewest ->
          ({ model | status = Loading, sort = "newest" }, Nav.pushUrl model.key ("gallery?page=" ++ String.fromInt 1 ++ "&sort=newest") )

        SortPopular ->
          ({ model | status = Loading, sort = "popular" }, Nav.pushUrl model.key ("gallery?page=" ++ String.fromInt 1 ++ "&sort=popular") )

        SortTop ->
          ({ model | status = Loading, sort = "rating" }, Nav.pushUrl model.key ("gallery?page=" ++ String.fromInt 1 ++ "&sort=rating") )
        Jump sort page ->
          (model, Cmd.batch [Nav.pushUrl model.key ("/gallery?page=" ++ String.fromInt page ++ "&sort=" ++ model.sort),Task.perform (\_ -> Empty) (Dom.setViewport 0 0) ])

view : Model -> Html Msg
view model =
  div[][
    h1[][ text "Image Gallery" ]
    , div [ class "help-block" ][ text "Browse images uploaded by our users" ]
    , hr [ style "width" "80%" ][]
    , div [ class "alert alert-info"
    , style "width" "80%" 
    , style "margin" "auto" ][
      text "Sort by: "
      , button[ onClick SortNewest
      , style "margin-right" "10px"
      , style "background" "Transparent"
      , style "outline" "none"
      , style "border" "none"
      , if model.sort == "newest" then style "text-decoration" "underline"
      else style "" "" ][ text "Newest" ]
      , button[ onClick SortPopular
      , style "margin-right" "10px"
      , style "background" "Transparent"
      , style "outline" "none"
      , style "border" "none"
      , if model.sort == "popular" then style "text-decoration" "underline"
      else style "" ""  ] [ text "Most Popular" ]
      , button[ onClick SortTop
      , style "background" "Transparent"
      , style "outline" "none"
      , style "border" "none"
      , if model.sort == "rating" then style "text-decoration" "underline"
      else style "" ""  ] [ text "Top Rated"]
    ]
    , div [ class "help-block", style "margin-top" "20px" ] [
      text "Currently sorting by: "
      , case model.sort of
        "rating" ->
          text "Top rated first"
        "popular" ->
          text "Most popular first"
        "newest" ->
          text "Newest first"
        _ ->
          text "Invalid sort method"
    ]
    , case model.status of
        Loading ->
          div [ style "margin-top" "50px" ] [
            h3 [] [ text "Fetching data from the server" ]
            , Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
          ]

        Failure ->
          div [ class "alert alert-danger"
          , style "margin-top" "50px"
          , style "width" "60%"
          , style "margin" "auto"
          , style "margin-top" "50px" ] [
            h4 [] [ text "Gallery failed to load" ]
          ]

        Success container ->
          let 
            images = container.images
          in
            div[][
              if List.isEmpty images then
                div [ class "alert alert-warning"
                , style "margin" "auto"
                , style "width" "50%"
                , style "margin-top" "50px" ][
                  text "There are no images in the gallery"
                ]
              else 
                div [ class "panel panel-default"
                , style "border" "none" ]
                  (List.map Image.showPreview images)
                , div [ style "margin-top" "20px" ] [
                  div [ style "width" "30%"
                  , style "margin" "auto" ] ((List.range 1 ( ceiling ( toFloat container.total / toFloat pageSize ))) |> List.map (viewButton model) )
                  , div [ class "help-block" ] [ text ( String.fromInt(model.page) ++ "/" ++ String.fromInt( ceiling ( toFloat container.total / toFloat pageSize ) ) )]
                ]
            ]
  ]

viewButton: Model -> Int -> Html Msg
viewButton model num =
  button[ class "btn btn-default"
  , if model.page == num then
      style "opacity" "0.3"
    else
      style "" ""
  , onClick (Jump model.sort num)
  ][
      text (String.fromInt num)
  ]

getSort: String -> String
getSort sort =
  case sort of
        "popular" ->
          "views"
        "rating" ->
          "points"
        _ ->
          "uploaded"

get : String -> Int -> Cmd Msg
get sort page =
    Http.get
      { 
        url = Server.url ++ "/images/get" ++ "?page=" ++ (String.fromInt page)
            ++ "&sort=" ++ (getSort sort) ++ "&order=" ++ (String.fromInt -1)
        , expect = Http.expectJson Response Image.decodePreviewContainer
      }