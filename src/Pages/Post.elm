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
    , comment: String
    , id: String
  }

type Status
  = Loading
  | Success Image.Model
  | Failure

type Msg
  = Response (Result Http.Error (Image.Model))
  | CommentResponse (Result Http.Error())
  | Comment String
  | Submit

init: Nav.Key -> Maybe User.Model -> String -> (Model, Cmd Msg)
init key user fragment =
    (Model key user Loading "" "", post fragment)

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Response response ->
            case response of
                Ok image ->
                    ({ model | status = Success image, id = image.id }, Cmd.none)
                Err _ ->
                    ({ model | status = Failure }, Cmd.none)

        CommentResponse response ->
            case response of
                Ok _ ->
                    (model, Nav.reload)
                Err _ ->
                    (model, Cmd.none)

        Comment string ->
            ({ model | comment = string }, Cmd.none)

        Submit ->
            case model.user of
                Just user -> 
                    ({ model | comment = "" }, postComment model.id user.username user.avatar model.comment)
                _ ->
                    (model, Cmd.none)

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
                    , style "margin-bottom" "50px" ][]
                    , img [ src image.url
                    , style "max-width" "1000px"
                    , style "max-height" "1500px" ] []
                    --, div [] [ span [ class "glyphicon glyphicon-heart" ] [] ]
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
                                , style "margin-top" "20px" ]
                                    (List.map Tag.view image.tags)
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
                ]
                , h2 [] [ text ("Comments (" ++ String.fromInt (List.length image.comments) ++ ")") ]
                , case List.isEmpty image.comments of
                    True ->
                        div [ style "font-style" "italic" ] [ text "No comments" ] 
                    False ->
                        div [] (List.map viewComment image.comments)
                , div [ class "help-block"
                , style "margin-top" "20px" ] [ text "Leave a comment on this post" ]
                , case model.user of
                    Just user ->
                        div[][
                            textarea [ cols 100
                            , rows 7 
                            , style "resize" "none"
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

encodeComment: String -> String -> String -> String -> Encode.Value
encodeComment id username url content = 
    Encode.object[
        ("id", Encode.string id)
        , ("username", Encode.string username)
        , ("url", Encode.string url)
        , ("content", Encode.string content)
    ] 

postComment: String -> String -> String -> String -> Cmd Msg
postComment id username url content =
    Http.post
      { 
        url = Server.url ++ "/images/comment"
        , body = Http.jsonBody <| encodeComment id username url content
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