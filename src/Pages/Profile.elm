module Pages.Profile exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import User
import Server
import File exposing (File, size, name)
import File.Select as Select
import Json.Decode as Decode exposing (Decoder, field, string, int)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import Json.Encode as Encode exposing (..)
import LineChart
import Social
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Time
import Image
import TimeFormat
import Pages.Profile.Settings as SettingsTab
import Pages.Profile.Security as SecurityTab
import Pages.Profile.History as HistoryTab
import Pages.Profile.Favorites as FavoritesTab
import Markdown

{--
    Display a profile of user. This page shows up both when you display your own profile
    and when you display a profile of another user. Because signing in immediately downloads
    all user info and stores it in application state, when you display your own profile a new request
    is not necessary. Based on url, the app decides if the profile is yours. If it's not, it send a request
    with the profile name (obtained from url) to obtain the info about the user whose profile you are viewing.
--}

postCount = 5

type alias Model =
  {  
    user: User.Model
    , key: Nav.Key
    , tab: Tab
    , fragment: String
    , status: Status
    , postsStatus: PostsStatus
  }

init: Nav.Key -> User.Model -> String -> ( Model, Cmd Msg)
init key user fragment = 
    if fragment == user.username then
        --if logged in user is viewing his own profile
        (Model user key Information fragment Success LoadingPosts, Cmd.batch [ getPosts fragment postCount ])
    else 
        --if logged in user is viewing profile of someone else
        (Model user key Information fragment Loading LoadingPosts, Cmd.batch [ loadUser fragment, getPosts fragment postCount ])

type Status
  = Loading
  | Success
  | Failure

type PostsStatus
  = LoadingPosts
  | FailurePosts
  | SuccessPosts (List Image.Preview)

type Msg
  = SwitchInformation
  | SwitchFavorites
  | SwitchSettings
  | SwitchSecurity
  | SwitchHistory
  | HistoryMsg HistoryTab.Msg
  | SettingsMsg SettingsTab.Msg
  | SecurityMsg SecurityTab.Msg
  | FavoritesMsg FavoritesTab.Msg
  | Select
  | GotFile File
  | PostsResponse (Result Http.Error (List Image.Preview))
  | AvatarResponse (Result Http.Error())
  | Response (Result Http.Error User.Model)
  | LoadMore

type Tab
  = Information
  | Favorites FavoritesTab.Model
  | Settings SettingsTab.Model
  | Security SecurityTab.Model
  | History HistoryTab.Model

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SwitchInformation ->
        ({ model | tab = Information }, Cmd.none)

    SwitchSettings ->
        ({ model | tab = Settings (SettingsTab.getModel (SettingsTab.init model.user) ) }, Cmd.none)

    SwitchSecurity ->
        ({ model | tab = Security (SecurityTab.getModel (SecurityTab.init model.key model.user) ) }, Cmd.none)

    SwitchHistory ->
        ({ model | tab = History (HistoryTab.getModel ( HistoryTab.init model.user ) ) }, Cmd.map HistoryMsg (HistoryTab.get model.user.username 5))

    SwitchFavorites ->
        ({ model | tab = Favorites (FavoritesTab.getModel (FavoritesTab.init model.user ) ) }, Cmd.map FavoritesMsg (FavoritesTab.getFavs model.fragment))

    --same approach as in Main.elm, step functions are used to convert types
    SettingsMsg mesg ->
        case model.tab of
            Settings sett -> 
                stepSettings model (SettingsTab.update mesg sett)
            _ -> 
                (model, Cmd.none)

    SecurityMsg mesg ->
        case model.tab of
            Security sec -> 
                stepSecurity model (SecurityTab.update mesg sec)
            _ -> 
                (model, Cmd.none)

    HistoryMsg mesg ->
        case model.tab of
            History hist -> 
                stepHistory model (HistoryTab.update mesg hist)
            _ -> 
                (model, Cmd.none)

    FavoritesMsg mesg ->
        case model.tab of
            Favorites fav ->
                stepFavorites model (FavoritesTab.update mesg fav)
            _ ->
                (model, Cmd.none)

    Select ->
        --profile pictures can be only images
        (model, Select.file ["image/*"] GotFile)

    --handle image upload (when changing profile picture)
    GotFile file ->
        let
            username = model.user.username
        in
            (model, put file username)

    AvatarResponse response ->
        case response of
            Ok _ ->
                (model, Nav.reload)
            Err log ->
                (model, Cmd.none)

    Response response ->
        case response of
            Ok user ->
                ({ model | user = user, status = Success }, Cmd.none)
            Err log ->
                ({ model | status = Failure }, Cmd.none)

    LoadMore ->
            (model, getPosts model.user.username 0)

    PostsResponse response ->
        case response of
            Ok posts ->
                ({ model | postsStatus = SuccessPosts posts }, Cmd.none)
            Err log ->
                ({ model | postsStatus = FailurePosts }, Cmd.none)

stepSettings: Model -> (SettingsTab.Model, Cmd SettingsTab.Msg) -> (Model, Cmd Msg)
stepSettings model ( settings, cmd ) =
  ({ model | tab = Settings settings }, Cmd.map SettingsMsg cmd)

stepSecurity: Model -> (SecurityTab.Model, Cmd SecurityTab.Msg) -> (Model, Cmd Msg)
stepSecurity model ( sec, cmd ) =
  ({ model | tab = Security sec }, Cmd.map SecurityMsg cmd)

stepHistory: Model -> (HistoryTab.Model, Cmd HistoryTab.Msg) -> (Model, Cmd Msg)
stepHistory model ( hist, cmd ) =
  ({ model | tab = History hist }, Cmd.map HistoryMsg cmd)

stepFavorites: Model -> (FavoritesTab.Model, Cmd FavoritesTab.Msg) -> (Model, Cmd Msg)
stepFavorites model ( fav, cmd ) =
  ({ model | tab = Favorites fav }, Cmd.map FavoritesMsg cmd)


view: Model -> Html Msg
view model =
  let 
    user = model.user
  in 
    div[][
        case model.status of
            Loading ->
                div [ style "height" "400px"
                , style "margin-top" "25%"
                , style "text-align" "center" ] [
                    h2 [] [ text "Fetching data from the server" ]
                    , Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
                ]
            Failure ->
                div [ style "height" "400px"
                , style "margin-top" "25%"
                , style "text-align" "center" ] [
                    h2 [] [ text "Profile failed to load" ]
                ]
            Success ->
                div[][
                    div[ class "jumbotron" ][
                        img [ class "avatar"
                        , attribute "draggable" "false"
                        , style "border" "10px solid white"
                        , src user.avatar
                        , style "border-radius" "50%"
                        , height 300
                        , width 300
                        , if user.token /= "Hidden" then
                            onClick Select 
                        else
                            style "" ""
                        ] []
                        , br [] []
                        , h3 [] [ text user.username
                                , if user.verif == True then 
                                    span [ class "glyphicon glyphicon-ok-circle"
                                    , style "color" "green"
                                    , style "margin-left" "5px"
                                    , title "Verified" ][]
                                else
                                    span [ class "glyphicon glyphicon-remove-circle"
                                    , style "color" "red"
                                    , style "margin-left" "5px"
                                    , title "Not verified" ] []
                        ]
                        , div [ style "margin-bottom" "20px" ] [
                            ul [ class "nav" ] [
                                case user.facebook of
                                    Just url ->
                                        Social.viewFacebook url
                                    Nothing ->
                                        text ""
                                , case user.twitter of
                                    Just url ->
                                        Social.viewTwitter url
                                    Nothing ->
                                        text ""
                                , case user.github of
                                    Just url ->
                                        Social.viewGithub url
                                    Nothing ->
                                        text ""
                            ]
                        ]
                        , div [ style "width" "50%" 
                        , style "margin" "auto" ][
                            i[ class "help-block" ][ text user.bio ] 
                        ]
                    ]
                    , if user.token /= "Hidden" then
                        div[][
                            ul [ class "nav nav-pills"
                            , style "margin-top" "-30px" ][
                                li [][ 
                                    button [ style "color" "black"
                                    , class "preview"
                                    , onClick SwitchInformation
                                    , style "border" "none"
                                    , style "background" "Transparent"
                                    , style "outline" "none" ][ 
                                        h4[][ text "Information" ]
                                    ]
                                    , case model.tab of 
                                        Information ->
                                            hr[ style "width" "90%"
                                            , style "margin-top" "-5px"
                                            , style "border" "1.5px solid #00acee" ][]
                                        _ ->
                                            text ""
                                ]
                                , li [][ 
                                    button [ style "color" "black"
                                    , class "preview"
                                    , onClick SwitchFavorites
                                    , style "border" "none"
                                    , style "background" "Transparent"
                                    , style "outline" "none" ][ 
                                        h4[][ text "Favorites" ]
                                    ]
                                    , case model.tab of 
                                        Favorites _ ->
                                            hr[ style "width" "90%"
                                            , style "margin-top" "-5px"
                                            , style "border" "1.5px solid #00acee" ][]
                                        _ ->
                                            text "" 
                                ]
                                , li [][ 
                                    button [ style "color" "black"
                                    , class "preview"
                                    , onClick SwitchSettings
                                    , style "border" "none"
                                    , style "background" "Transparent"
                                    , style "outline" "none" ][ 
                                        h4[][ text "Settings" ]
                                    ]
                                    , case model.tab of 
                                        Settings _ ->
                                            hr[ style "width" "90%"
                                            , style "margin-top" "-5px"
                                            , style "border" "1.5px solid #00acee" ][]
                                        _ ->
                                            text "" 
                                ]
                                , li [][ 
                                    button [ style "color" "black"
                                    , class "preview"
                                    , onClick SwitchSecurity
                                    , style "border" "none"
                                    , style "background" "Transparent"
                                    , style "outline" "none" ][ 
                                        h4[][ text "Security" ] 
                                    ] 
                                    , case model.tab of 
                                        Security _ ->
                                            hr[ style "width" "90%"
                                            , style "margin-top" "-5px"
                                            , style "border" "1.5px solid #00acee" ][]
                                        _ ->
                                            text ""
                                ]
                                , li [][ 
                                    button [ style "color" "black"
                                    , class "preview"
                                    , onClick SwitchHistory
                                    , style "border" "none"
                                    , style "background" "Transparent"
                                    , style "outline" "none" ][ 
                                        h4[][ text "History" ] 
                                    ]
                                    , case model.tab of 
                                        History _ ->
                                            hr[ style "width" "90%"
                                            , style "margin-top" "-5px"
                                            , style "border" "1.5px solid #00acee" ][]
                                        _ ->
                                            text "" 
                                ] 
                            ]
                        ]
                        else
                            text ""
                    , case model.tab of
                        Information ->
                            div[ class "list-group" ][
                                h3 [] [ text "Account information" ]
                                , div [ class "help-block" ][ 
                                    text ("Here are some information about " ++ user.username ++ "'s account")
                                ]
                                , text ("Registered at " ++ TimeFormat.formatDate user.registered)
                                , hr [][]
                                , h3 [] [ text "Post history" ]
                                , div [ class "help-block" ][
                                    text ("Preview of " ++ user.username ++ "'s posts")
                                ]
                                , case model.postsStatus of
                                    LoadingPosts ->
                                        div [] [
                                            Loader.render Loader.Circle Loader.defaultConfig Loader.On
                                        ]
                                    FailurePosts ->
                                        div [ class "alert alert-warning"
                                        , style "width" "50%"
                                        , style "margin" "auto" ][
                                            text "Connection error"
                                        ]
                                    SuccessPosts posts ->
                                        if List.isEmpty posts == True then
                                            div [ style "font-style" "italic" ][
                                                text "This user has no posts" 
                                            ]
                                        else
                                            div [] [
                                                div [] (List.map Image.showTab posts)
                                                , if List.length posts == postCount then
                                                    button [ class "btn btn-primary"
                                                    , onClick LoadMore ][
                                                        text "Load more"
                                                    ]
                                                else
                                                    text ""
                                            ]
                            ]

                        Settings tab ->
                            SettingsTab.view tab |> Html.map SettingsMsg

                        Security tab ->
                            SecurityTab.view tab |> Html.map SecurityMsg

                        History tab ->
                            HistoryTab.view tab |> Html.map HistoryMsg

                        Favorites tab ->
                            FavoritesTab.view tab |> Html.map FavoritesMsg
                ]
    ]


stringEncoder: String -> String -> Encode.Value
stringEncoder key value =
    Encode.object [(key, Encode.string value)]

put : File -> String -> Cmd Msg
put file user = 
  --upload profile picture
  Http.request
    { method = "PUT"
    , headers = [ Http.header "name" (File.name file), Http.header "user" user ]
    , url = Server.url ++ "/upload/profile"
    , body = Http.fileBody file 
    , expect = Http.expectWhatever AvatarResponse
    , timeout = Nothing
    , tracker = Nothing
    }

loadUser: String -> Cmd Msg
loadUser username = 
  Http.get
    { 
    --load user info if the profile is not the users
    url = Server.url ++ "/account/user" ++ "?username=" ++ username
    , expect = Http.expectJson Response User.decodeUserNotLoggedIn
    }

getPostsEncoder: String -> Int -> Encode.Value
getPostsEncoder username limit =
    Encode.object
    [
        ("username", Encode.string username)
        ,("limit", Encode.int limit)
    ]

getPosts: String -> Int -> Cmd Msg
getPosts username limit =
    --get posts of the user with limit value applied
    Http.get
    {   
        url = Server.url ++ "/account/posts" ++ "?username=" ++ username 
              ++ "&limit=" ++ (String.fromInt limit) 
        , expect = Http.expectJson PostsResponse (Decode.list Image.decodePreview)
    }