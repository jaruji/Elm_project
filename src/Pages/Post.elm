module Pages.Post exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import User
import Session
import Server
import File exposing (File, size, name)
import File.Select as Select
import Json.Decode as Decode exposing (Decoder, field, string, int)
import Json.Encode as Encode exposing (..)
import FeatherIcons as Icons
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Image
import Image.Comment as Comment
import Tag
import TimeFormat

type alias Model =
  { 
    key: Nav.Key
    , user: Maybe User.Model
    , status: Status
    , comments: CommentStatus
    , comment: String
    , id: String
  }

type Status
  = Loading
  | Success Image.Model
  | Failure

type CommentStatus
  = LoadingComments
  | SuccessComments (List Comment.Model)
  | FailureComments


type Msg
  = Response (Result Http.Error (Image.Model))
  | LoadComments (Result Http.Error (List Comment.Model))
  | CommentResponse (Result Http.Error())
  | RateResponse (Result Http.Error())
  | Comment String
  | Submit
  | Upvote
  | Downvote

init: Nav.Key -> Maybe User.Model -> String -> (Model, Cmd Msg)
init key user fragment =
    (Model key user Loading LoadingComments "" "", Cmd.batch [ post fragment, loadComments fragment ])

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Response response ->
            case response of
                Ok image ->
                    ({ model | status = Success image, id = image.id }, Cmd.none)
                Err _ ->
                    ({ model | status = Failure }, Cmd.none)

        LoadComments response ->
            case response of
                Ok comments ->
                    ({ model | comments = SuccessComments comments }, Cmd.none)
                Err _ ->
                    ({ model | comments = FailureComments }, Cmd.none)

        CommentResponse response ->
            case response of
                Ok _ ->
                    (model, loadComments model.id)
                Err _ ->
                    (model, Cmd.none)

        RateResponse response ->
            (model, Cmd.none)

        Comment string ->
            ({ model | comment = string }, Cmd.none)

        Submit ->
            case model.user of
                Just user -> 
                    if model.comment == "" then
                        (model, Cmd.none)
                    else
                        ({ model | comment = "" }, postComment model.id user.username model.comment)
                _ ->
                    (model, Cmd.none)

        Upvote ->
            (model, rate 1 model.id)

        Downvote ->
            (model, rate -1 model.id)

view: Model -> Html Msg
view model =
    case model.status of
        Loading ->
            div [] [
                text "Loading..."
            ]

        Failure ->
            div[] [
                text "Mission failed..."
            ]

        Success image ->
            div[ style "margin-top" "-40px" ] [
                div [ class "jumbotron" ][
                    div[][
                        h1[ style "max-width" "1000px"
                        , style "margin" "auto" ][ text image.title ]
                        , h4 [ class "float-right" ] [
                            text "Uploaded by "
                            , a [ href ("/profile/" ++ image.author) ][ text image.author ]
                            , text (" on " ++ TimeFormat.formatTime image.uploaded) 
                        ]
                    ]
                    , hr[ style "width" "50%"
                    , style "margin" "auto"
                    , style "margin-bottom" "5px" ][]
                    , div [ class "help-block" ] [ text ("This image has " ++ String.fromInt image.views ++ " views") ]
                    , img [ src image.url
                    , style "max-width" "1000px"
                    , style "max-height" "1500px" ] []
                    , div [ style "width" "50%"
                    , class "help-block"
                    , style "margin" "auto"
                    , style "margin-top" "10px" ] [ text ("Image currently has " ++ String.fromInt image.points ++ " points")]
                    , div [] [ 
                        button [ class "btn btn-danger"
                        , style "margin-top" "10px"
                        , style "margin-right" "10px"
                        , style "color" "white"
                        , onClick Downvote ][
                            Icons.thumbsDown |> Icons.withSize 15 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] 
                        ]
                        , button [ class "btn btn-success"
                        , style "margin-top" "10px"
                        , style "color" "white"
                        , onClick Upvote ][
                            Icons.thumbsUp |> Icons.withSize 15 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] 
                        ] 
                    ]
                    , h3 [] [ text "Description" ]
                    , p [ style "font-size" "16px"
                    , style "max-width" "600px"
                    , style "margin" "auto" ][
                        case image.description of
                            "No description" ->
                                div [ style "font-style" "italic" ][ text image.description ]
                            _ -> 
                                text image.description 
                    ]
                    , case List.isEmpty image.tags of
                        True ->
                            div[][
                                h3 [] [ text "Tags" ]
                                , div [ style "font-style" "italic" ] [ text "No tags" ]
                            ]
                        False ->
                            div[][
                                h3 [] [ text "Tags" ]
                                , div [ style "max-width" "600px"
                                , style "margin" "auto"
                                , style "margin-top" "10px" ]
                                    (List.map Tag.view image.tags)
                            ]
                ]
                --COMMENTS SECTION HERE
                , case model.comments of
                    LoadingComments ->

                        div [] [
                            h2 [] [ text "Comments" ]
                            , Loader.render Loader.Circle Loader.defaultConfig Loader.On
                        ]
                    FailureComments ->
                        div [] [
                            h2 [] [ text "Comments" ]
                            , div [ class "alert alert-warning"
                            , style "width" "50%"
                            , style "margin" "auto" ] [ text "Comment section failed to load" ]
                        ]

                    SuccessComments comments ->
                        div [] [
                            h2 [] [ text ("Comments (" ++ String.fromInt (List.length comments) ++ ")") ]
                            , case List.isEmpty comments of
                                True ->
                                    div [ style "font-style" "italic" ] [ text "No comments" ] 
                                False ->
                                    div [] (List.map viewComment comments) 
                        ]
                , div [ class "help-block"
                , style "margin-top" "20px" ] [ text "Leave a comment on this post" ]
                , case model.user of
                    Just user ->
                        div[][
                            textarea [ cols 100
                            , rows 7 
                            , style "resize" "vertical"
                            , placeholder "Enter your comment"
                            , onInput Comment
                            , Html.Attributes.value model.comment ] []
                            , div[][ 
                                button [ class "btn btn-primary"
                                , onClick Submit ] [ text "Comment" ]
                            ]
                        ]
                    Nothing ->
                        div[ class "alert alert-warning"
                        , style "width" "30%" 
                        , style "margin" "auto"
                        , style "margin-top" "20px" ][
                            text "You must be logged in to comment"
                        ]
                , div [ class "row"
                , style "margin-top" "100px" ][]
            ]

viewComment: Comment.Model -> Html Msg
viewComment comment =
    div[ class "media"
    , style "width" "50%"
    , style "margin" "auto"
    , style "margin-bottom" "20px"  ][
    div[ class "media-left" ][
        img [ src comment.url
        , class "avatar"
        , height 80
        , width 80
        , style "border-radius" "50%" ][]
    ]
    , div[ class "media-body well"
    , style "text-align" "left" ][
        div [ class "media-heading" ][
            div [ class "help-block" ] [
                a [ href ("/profile/" ++ comment.username) ][ text comment.username ]   
                , text ( " on " ++ (TimeFormat.formatTime comment.date))
                --, text  (" " ++ String.fromInt comment.points ++ " points")
                {--
                , button [ style "color" "red"
                , class "pull-right"
                , style "height" "20px"
                , style "width" "20px"
                , style "border" "none"
                , style "background" "Transparent"
                , style "outline" "none" ][ span [ class "glyphicon glyphicon-remove" ] [] ]  
                , button [ style "color" "lightgreen"
                , class "pull-right"
                , style "height" "20px"
                , style "width" "20px"
                , style "border" "none"
                , style "background" "Transparent"
                , style "outline" "none" ][ span [ class "glyphicon glyphicon-pencil" ] [] ]
                --}
            ]
        ]
        , div[][
            text comment.content
        ]
    ]
 ]
   
encodeID: String -> Encode.Value
encodeID id =
  Encode.object[("id", Encode.string id)]

encodeComment: String -> String -> String -> Encode.Value
encodeComment id username content = 
    Encode.object[
        ("id", Encode.string id)
        , ("username", Encode.string username)
        , ("content", Encode.string content)
    ] 

encodeRate: Int -> String -> Encode.Value
encodeRate method id =
    Encode.object[
        ("method", Encode.int method)
        , ("id", Encode.string id)
    ]

rate: Int -> String -> Cmd Msg
rate method id = 
    Http.request
    {
        method = "PATCH"
        , headers = []
        , url = Server.url ++ "/images/rate"
        , body = Http.jsonBody <| (encodeRate method id)
        , expect = Http.expectWhatever RateResponse
        , timeout = Nothing
        , tracker = Nothing
    }

loadComments: String -> Cmd Msg
loadComments id =
    Http.post
      { 
        url = Server.url ++ "/comment/get"
        , body = Http.jsonBody <| encodeID id
        , expect = Http.expectJson LoadComments (Decode.list Comment.commentDecoder)
      }

postComment: String -> String -> String -> Cmd Msg
postComment id username content =
    Http.post
      { 
        url = Server.url ++ "/comment/add"
        , body = Http.jsonBody <| encodeComment id username content
        , expect = Http.expectWhatever CommentResponse
      }

post : String -> Cmd Msg
post id =
    Http.post
      { 
        url = Server.url ++ "/images/id"
        , body = Http.jsonBody <| encodeID id
        , expect = Http.expectJson Response Image.decodeImage
      }