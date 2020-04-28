module Pages.Post exposing (..)
import Browser
import Browser.Navigation as Nav
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Task
import User
import Server
import Json.Decode as Decode exposing (Decoder, field, string, int)
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import FeatherIcons as Icons
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Image
import Image.Comment as Comment
import Image.Stats as Stats
import Tag
import TimeFormat
import Markdown
import Time

type alias Model =
  { 
    key: Nav.Key
    , user: Maybe User.Model
    , status: Status
    , comments: CommentStatus
    , comment: String
    , id: String
    , stats: StatsStatus
    , vote: InfoStatus
    , editing: Maybe String
    , edit: String
    , deleting: Maybe String
  }

type alias Info =
  {
    vote: String
    , favorite: Bool
  }

type Status
  = Loading
  | Success Image.Model
  | Failure

type InfoStatus
  = LoadingInfo
  | FailureInfo
  | SuccessInfo Info

type CommentStatus
  = LoadingComments
  | SuccessComments (List Comment.Model)
  | FailureComments

type StatsStatus
  = LoadingStats
  | SuccessStats Stats.Model
  | FailureStats


type Msg
  = Response (Result Http.Error (Image.Model))
  | LoadComments (Result Http.Error (List Comment.Model))
  | CommentResponse (Result Http.Error())
  | RateResponse (Result Http.Error())
  | StatsResponse (Result Http.Error(Stats.Model))
  | InfoResponse (Result Http.Error Info)
  | ManageCommentResponse (Result Http.Error())
  | DeleteResponse (Result Http.Error())
  | Comment String
  | Submit
  | DeletePost String String
  | Upvote
  | Downvote
  | Veto
  | Favorite
  | Edit String String
  | EditCancel
  | EditConfirm
  | EditComment String
  | DeleteComment String
  | DeleteCommentCancel
  | DeleteCommentConfirm
  | Empty
  | Reload

init: Nav.Key -> Maybe User.Model -> String -> (Model, Cmd Msg)
init key user fragment =
    (Model key user Loading LoadingComments "" fragment LoadingStats LoadingInfo Nothing "" Nothing
    , Cmd.batch [
        get fragment
        , getUserInfo fragment user
        , loadComments fragment
        , Task.perform (\_ -> Empty) (Dom.setViewport 0 0)
    ])

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
            (model, Cmd.none)
        Response response ->
            case response of
                Ok image ->
                    ({ model | status = Success image, id = image.id }, loadStats model.id)
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
            case response of
                Ok _ ->
                    (model, Cmd.batch [loadStats model.id, getUserInfo model.id model.user])
                Err log ->
                    (model, Cmd.none)

        StatsResponse response ->
            case response of
                Ok stats ->
                    ({ model | stats = SuccessStats stats }, Cmd.none)
                Err _ ->
                    ({ model | stats = FailureStats }, Cmd.none)

        Comment string ->
            ({ model | comment = string }, Cmd.none)

        DeletePost id token ->
            (model, deletePost id token)

        DeleteResponse response ->
            case response of
                Ok _ ->
                    (model, Nav.pushUrl model.key "/")
                Err log ->
                    (model, Cmd.none)

        ManageCommentResponse response ->
            case response of
                Ok _ ->
                    (model, loadComments model.id)
                Err log ->
                    (model, Cmd.none)

        InfoResponse response ->
            case response of
                Ok info -> 
                    ({ model | vote = SuccessInfo info }, Cmd.none)
                Err log ->
                    ({ model | vote = FailureInfo }, Cmd.none)

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
            (model, rate model "upvote")

        Downvote ->
            (model, rate model "downvote")

        Veto ->
            (model, rate model "veto")

        Favorite ->
            (model, favorite model)

        EditComment string ->
            ({ model | edit = string }, Cmd.none)

        Edit id content ->
            ({ model | editing = (Just id), edit = content, deleting = Nothing }, Cmd.none)

        EditCancel ->
            ({ model | editing = Nothing, edit = "" }, Cmd.none)

        EditConfirm ->
            case model.editing of
                Just id ->
                    ({ model | edit = "", editing = Nothing }, editComment id model.edit)
                Nothing ->
                    ({ model | edit = "", editing = Nothing }, Cmd.none)

        DeleteComment id ->
            ({ model | deleting = (Just id), editing = Nothing }, Cmd.none)

        DeleteCommentConfirm ->
            case model.deleting of
                Just id ->
                    ({ model | deleting = Nothing }, deleteComment id)
                Nothing ->
                    ({ model | deleting = Nothing }, Cmd.none)

        DeleteCommentCancel ->
            ({ model | deleting = Nothing }, Cmd.none)

        Reload ->
            (model, Cmd.batch [ loadComments model.id, loadStats model.id ])

view: Model -> Html Msg
view model =
    case model.status of
        Loading ->
            div [] [
                text "Loading..."
            ]

        Failure ->
            div[] [
                text "Image failed to load..."
            ]

        Success image ->
            div[ style "margin-top" "-40px" ] [
                div [ class "jumbotron" ][
                    div[][
                        h1[ style "max-width" "1000px"
                        , style "margin" "auto" ][ text image.title ]
                        , h4 [ class "float-right" ][
                            text "Uploaded by "
                            , a [ href ("/profile/" ++ image.author) ][ text image.author ]
                            , text (" on " ++ TimeFormat.formatTime image.uploaded) 
                        ]
                    ]
                    , hr[ style "width" "60%"
                    , style "margin" "auto"
                    , style "margin-bottom" "20px" ][]
                    , img [ src image.url
                    , style "max-width" "1400px"
                    ] []
                    --
                    --STATS HERE
                    --
                    , h3[][ text "Stats"]
                    , div [ class "well" 
                    , style "width" "30%"
                    , style "height" "60px"
                    , style "margin" "auto"
                    , style "margin-top" "10px" ][
                        case model.stats of
                            LoadingStats ->
                                text "Loading..."
                            FailureStats ->
                                text "Failed to load stats"
                            SuccessStats stats ->
                                Stats.view stats
                    ]
                    , div [ style "margin-top" "10px" ][
                        case model.vote of
                                LoadingInfo ->
                                    text "Loading vote"
                                FailureInfo ->
                                    text "Failed to load vote"
                                SuccessInfo info ->
                                    div[][
                                        button [ style "background" "Transparent"
                                        , style "border" "none"
                                        , style "color" "darkgrey"
                                        , class "social"
                                        , style "outline" "none"
                                        , style "transition" "all 0.3s ease 0s"
                                        , case info.vote of
                                            "upvote" ->
                                                style "color" "lime"
                                                --, onClick Veto
                                            "invalid" ->
                                                disabled True
                                            "none" ->
                                                onClick Upvote
                                            "downvote" ->
                                                onClick Veto
                                            _ ->
                                                style "" ""
                                        ][ Icons.arrowUpCircle |> Icons.withSize 30 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] ]
                                        , button [ style "background" "Transparent"
                                        ,  style "border" "none"
                                        , style "color" "darkgrey"
                                        , class "social"
                                        , style "outline" "none"
                                        , style "transition" "all 0.3s ease 0s"
                                        , case info.vote of
                                            "downvote" ->
                                                style "color" "red"
                                                --, onClick Veto
                                            "invalid" ->
                                                disabled True
                                            "none" ->
                                                onClick Downvote
                                            "upvote" ->
                                                onClick Veto
                                            _ ->
                                                style "" ""
                                        ][ Icons.arrowDownCircle |> Icons.withSize 30 |> Icons.withStrokeWidth 2 |> Icons.toHtml [] ]
                                        , button[ style "background" "Transparent"
                                        , style "border" "none"
                                        , style "color" "darkgrey"
                                        , class "social"
                                        , style "outline" "none"
                                        , style "transition" "all 0.3s ease 0s"
                                        , case model.user of
                                            Nothing ->
                                                disabled True
                                            _ ->
                                                class ""
                                        , case info.favorite of
                                            True ->
                                                style "color" "red"
                                            False ->
                                                style "" ""
                                        , onClick Favorite ][ 
                                            Icons.heart |> Icons.withSize 30 |> Icons.withStrokeWidth 2 |> Icons.toHtml []
                                        ]
                                    ]   
                    ]                 
                    , h3 [][
                        text "Description"
                    ]
                    , case image.description of
                        "" ->
                            div [ style "font-style" "italic" ][ 
                                text "No description" 
                            ]
                        _ -> 
                            div[ class "media"
                            , style "margin" "auto"
                            , style "max-width" "50%" ][
                                div[ class "media-body well" ][
                                    div[ style "text-align" "center" ][
                                        i [ style "font-size" "14px" ][ 
                                            text image.description 
                                        ]
                                    ]
                                ]
                            ]
                    , case List.isEmpty image.tags of
                        True ->
                            div[][
                                h3 [] [ text "Tags" ]
                                , div [ style "font-style" "italic" ] [ text "No tags" ]
                            ]
                        False ->
                            div[][
                                h3 [] [ text "Tags"]
                                , div [ style "max-width" "600px"
                                , style "margin" "auto"
                                , style "margin-top" "10px" ]
                                    (List.map Tag.view image.tags)
                            ]
                ]
                , case model.user of
                        Just user ->
                            if user.username == image.author then
                                button [ class "btn btn-danger" 
                                , onClick (DeletePost image.id user.token) ][
                                    text "Remove post"
                                ]
                            else
                                text ""
                        Nothing ->
                            text ""
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
                                    div [] (List.map (viewComment model) comments) 
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
                            text "You must be "
                            , a [ href "/sign_in" ][ text "signed in" ]
                            , text " to comment"
                        ]
                , div [ class "row"
                , style "margin-top" "100px" ][]
            ]

viewComment: Model -> Comment.Model -> Html Msg
viewComment model comment =
    div[ class "media"
    , style "width" "60%"
    , style "margin" "auto"
    , style "margin-bottom" "20px"  ][
    div[ class "media-left" ][
        a [ href ("/profile/" ++ comment.username) ][
            img [ src comment.url
            , class "avatar"
            , attribute "draggable" "false"
            , height 80
            , width 80
            , style "border-radius" "50%" ][]
        ]
    ]
    , div[ class "media-body well"
    , style "text-align" "left" ][
        div [ class "media-heading" ][
            div [ class "help-block" ][
                a [ href ("/profile/" ++ comment.username) ][ text comment.username ]   
                , text ( " on " ++ (TimeFormat.formatTime comment.date))
                , case comment.edited of
                    Just date ->
                        text (" • Edited on " ++ (TimeFormat.formatTime date ))
                    Nothing ->
                        text ""
                , case model.user of
                    Just user ->
                        if user.username == comment.username then
                            span[][
                                button [ style "color" "red"
                                    , style "transition" "all 0.3s ease 0s"
                                    , class "pull-right social"
                                    , style "height" "20px"
                                    , style "width" "20px"
                                    , style "border" "none"
                                    , style "background" "Transparent"
                                    , title "Delete"
                                    , onClick (DeleteComment comment.id)
                                    , style "outline" "none" ][ span [ 
                                        class "glyphicon glyphicon-trash" ] [] 
                                    ]  
                                , button [ style "color" "#3b5998"
                                    , style "transition" "all 0.3s ease 0s"
                                    , class "pull-right social"
                                    , style "height" "20px"
                                    , style "width" "20px"
                                    , style "border" "none"
                                    , style "background" "Transparent"
                                    , onClick (Edit comment.id comment.content)
                                    , title "Edit"
                                    , style "outline" "none" ][ span [ 
                                        class "glyphicon glyphicon-pencil" ] [] 
                                    ]
                            ]
                        else
                            text ""
                    Nothing ->
                        text ""
            ]
        ]
        , div[][
            if model.editing == (Just comment.id) then
                div[][
                    textarea [ id "edit"
                    , placeholder comment.content
                    , style "outline" "none"
                    , style "border" "none"
                    , style "width" "100%"
                    , style "min-height" "100px"
                    , style "resize" "vertical"
                    , style "background" "Transparent"
                    , onInput EditComment
                    , Html.Attributes.value model.edit
                    ] []
                    , div[][
                        button [ class "btn btn-success btn-sm"
                        , onClick EditConfirm
                        , class "pull-right" ][
                            text "Confirm"
                        ]
                        , button [ class "btn btn-default btn-sm"
                        , onClick EditCancel
                        , style "margin-right" "5px"
                        , class "pull-right" ][
                            text "Cancel"
                        ]
                    ]
                ]
            else
                Markdown.toHtml [ class "content" ]  comment.content
            , if model.deleting == (Just comment.id) then
                div[][
                        button [ class "btn btn-danger btn-sm"
                        , onClick DeleteCommentConfirm
                        , class "pull-right" ][
                            text "Confirm"
                        ]
                        , button [ class "btn btn-default btn-sm"
                        , onClick DeleteCommentCancel
                        , style "margin-right" "5px"
                        , class "pull-right" ][
                            text "Cancel"
                        ]
                    ]
            else
                text ""
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

encodeRate: String -> String -> Encode.Value
encodeRate vote id =
    Encode.object[
        ("vote", Encode.string vote)
        , ("id", Encode.string id)
    ]

rate: Model -> String -> Cmd Msg
rate model vote = 
    Http.request
    {
        method = "POST"
        , headers = case model.user of
            Just user ->
                [ Http.header "auth" user.token ]
            Nothing ->
                []
        , url = Server.url ++ "/image/rate"
        , body = Http.jsonBody <| (encodeRate vote model.id)
        , expect = Http.expectWhatever RateResponse
        , timeout = Nothing
        , tracker = Nothing
    }

favorite: Model -> Cmd Msg
favorite model =
    Http.request
    {
        method = "POST"
        , headers = case model.user of
            Just user ->
                [ Http.header "auth" user.token ]
            Nothing ->
                []
        , url = Server.url ++ "/image/favorite"
        , body = Http.jsonBody <| encodeID model.id
        , expect = Http.expectWhatever RateResponse
        , timeout = Nothing
        , tracker = Nothing
    }


loadComments: String -> Cmd Msg
loadComments id =
    Http.get
      { 
        url = Server.url ++ "/comment/get" ++ "?id=" ++ id
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

encodeEdit: String -> String -> Encode.Value
encodeEdit id comment =
    Encode.object[
        ("id", Encode.string id)
        , ("comment", Encode.string comment)
    ]

editComment: String -> String -> Cmd Msg
editComment id comment =
    Http.request
      {   
        method = "PATCH"
        , headers = []
        , url = Server.url ++ "/comment/edit"
        , body = Http.jsonBody <| encodeEdit id comment
        , expect = Http.expectWhatever ManageCommentResponse
        , timeout = Nothing
        , tracker = Nothing
      }

deleteComment: String -> Cmd Msg
deleteComment id =
    Http.request
      {   
        method = "DELETE"
        , headers = []
        , url = Server.url ++ "/comment/delete"
        , body = Http.jsonBody <| encodeID id
        , expect = Http.expectWhatever ManageCommentResponse
        , timeout = Nothing
        , tracker = Nothing
      }

get: String -> Cmd Msg
get id =
    Http.request
      {   
        method = "GET"
        , headers = []
        , url = Server.url ++ "/image" ++ "?id=" ++ id
        , body = Http.emptyBody
        , expect = Http.expectJson Response Image.decodeImage
        , timeout = Nothing
        , tracker = Nothing
      }

deletePost: String -> String -> Cmd Msg
deletePost id token =
    Http.request
      {   
        method = "DELETE"
        , headers = [ Http.header "auth" token ]
        , url = Server.url ++ "/image/delete"
        , body = Http.jsonBody <| encodeID id
        , expect = Http.expectWhatever DeleteResponse
        , timeout = Nothing
        , tracker = Nothing
      }
loadStats: String -> Cmd Msg
loadStats id =
    Http.get
      {   
        url = Server.url ++ "/image/stats" ++ "?id=" ++ id
        , expect = Http.expectJson StatsResponse Stats.statsDecoder
      }

decodeUserInfo: Decode.Decoder Info
decodeUserInfo =
    Decode.succeed Info
    |> required "vote" Decode.string
    |> required "favorite" Decode.bool


getUserInfo: String -> Maybe User.Model -> Cmd Msg
getUserInfo id mbyUser =
    Http.request
      {   
        method = "GET"
        , headers = [
            case mbyUser of 
                Just user ->
                    Http.header "auth" user.token
                Nothing ->
                    Http.header "auth" ""
        ]
        , url = Server.url ++ "/image/info" ++ "?id=" ++ id
        , body = Http.emptyBody
        , expect = Http.expectJson InfoResponse decodeUserInfo
        , timeout = Nothing
        , tracker = Nothing
      }


subscriptions: Model -> Sub Msg
subscriptions model =
    Time.every 30000 (\_ ->
        ( 
            Reload
        )
    )