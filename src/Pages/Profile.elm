module Pages.Profile exposing (..)
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
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import Json.Encode as Encode exposing (..)
import LineChart
import FeatherIcons as Icons
import Social
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Time
import TimeFormat

type alias Model =
  {  
    user: User.Model
    , key: Nav.Key
    , tab: Tab
    , code: String
    , bio: String
    , firstName : String
    , surname: String
    , occupation: String
    , facebook: String
    , twitter: String
    , github: String
    , fragment: String
    , status: Status
    , posts: PostStatus
  }


init: Nav.Key -> User.Model -> String -> ( Model, Cmd Msg, Session.UpdateSession)
init key user fragment = 
    if fragment == user.username then
        (Model user key Information "" "" "" "" "" "" "" "" fragment Success LoadingPost, getPosts user.username, Session.NoUpdate)
    else 
        (Model user key Information "" "" "" "" "" "" "" "" fragment Loading LoadingPost, Cmd.batch [ loadUser fragment, getPosts fragment ], Session.NoUpdate)

type alias PostPreview =
  { 
    title: String
    , uploaded: Time.Posix
    , id: String
    , url: String 
  }

type alias Point =
  { 
    x : Float
    , y : Float 
  }

type PostStatus
 = LoadingPost
 | SuccessPost (List PostPreview)
 | FailurePost

type Status
  = Loading
  | Success
  | Failure

type Msg
-- Switch msg are used for switching tabs
  = SwitchInformation
  | SwitchSettings
  | SwitchSecurity
  | SwitchHistory
-- Here are msgs needed for updating and handling all inputs
  | Bio String
  | FirstName String
  | Surname String
  | Occupation String
  | Facebook String
  | Twitter String
  | Github String
  --}
  --| OldPassword String
  --| NewPassword String
  --| NewPasswordA String
--submit update
  | UpdateSettings
  | Request
  | Code String
  | Verify
  | MailResponse (Result Http.Error())
  | AvatarResponse (Result Http.Error String)
  | VerifyResponse (Result Http.Error Bool)
  | PostsResponse (Result Http.Error (List PostPreview))
  | UpdateResponse  (Result Http.Error())
  | Response (Result Http.Error User.Model)
  | Select
  | GotFile File

type Tab
  = Information
  | Settings
  | Security
  | History

update: Msg -> Model -> ( Model, Cmd Msg, Session.UpdateSession )
update msg model =
  case msg of
    SwitchInformation ->
        ({model | tab = Information}, Cmd.none, Session.NoUpdate)
    SwitchSettings ->
        ({model | tab = Settings}, Cmd.none, Session.NoUpdate)
    SwitchSecurity ->
        ({model | tab = Security}, Cmd.none, Session.NoUpdate)
    SwitchHistory ->
        ({model | tab = History}, Cmd.none, Session.NoUpdate)
    Request ->
        (model, requestMail model.user.email, Session.NoUpdate)
    Select ->
        (model, Select.file ["image/*"] GotFile, Session.NoUpdate)
    GotFile file ->
        let
            username = model.user.username
        in
            (model, put file username, Session.NoUpdate)
    Verify -> 
        (model, verifyCode model, Session.NoUpdate)
    VerifyResponse response ->
        case response of
            Ok bool ->
                case bool of
                    True ->
                        ({model | user = verifyUser model.user}, Cmd.none, Session.Update (verifyUser model.user)) 
                    False ->
                        (model, Cmd.none, Session.NoUpdate)
            Err log ->
                (model, Cmd.none, Session.NoUpdate)

    AvatarResponse response ->
        case response of
            Ok string ->
                (model, Nav.reload, Session.NoUpdate)
            Err log ->
                (model, Cmd.none, Session.NoUpdate)

    MailResponse _ ->
        (model, Cmd.none, Session.NoUpdate)

    PostsResponse response ->
        case response of
            Ok posts ->
                ({ model | posts = SuccessPost posts }, Cmd.none, Session.NoUpdate)
            Err log ->
                ({ model | posts = FailurePost }, Cmd.none, Session.NoUpdate)

    UpdateResponse response ->
        case response of
            Ok _ -> 
                (model, Nav.reload, Session.NoUpdate)
            Err log ->
                (model, Cmd.none, Session.NoUpdate)

    Response response ->
        case response of
            Ok user ->
                ({ model | user = user, status = Success }, Cmd.none, Session.NoUpdate)
            Err log ->
                ({ model | status = Failure }, Cmd.none, Session.NoUpdate)

    Code string ->
        ({model | code = string}, Cmd.none, Session.NoUpdate)

    Bio string ->
        ({model | bio = string}, Cmd.none, Session.NoUpdate)

    FirstName string ->
        ({model | firstName = string}, Cmd.none, Session.NoUpdate)

    Surname string -> 
        ({model | surname = string}, Cmd.none, Session.NoUpdate)

    Occupation string ->
        ({model | occupation = string}, Cmd.none, Session.NoUpdate)

    Facebook string ->
        ({model | facebook = string}, Cmd.none, Session.NoUpdate)

    Twitter string ->
        ({model | twitter = string}, Cmd.none, Session.NoUpdate)

    Github string ->
        ({model | github = string}, Cmd.none, Session.NoUpdate)

    UpdateSettings ->
        if model.bio == "" || model.firstName == "" || model.surname == "" 
        || model.occupation == "" || model.facebook == "" || model.twitter == "" 
        || model.github == "" then
            (model, Cmd.none, Session.NoUpdate)
        else
            (model, patch model model.user.token, Session.NoUpdate)

verifyUser: User.Model -> User.Model
verifyUser user =
    { user | verif = True }

updateAvatar: String -> User.Model -> User.Model
updateAvatar avatar user =
    { user | avatar = avatar }
    

view: Model -> Html Msg
view model =
  let 
    user = model.user
  in 
    div[][
        case model.status of
            Loading ->
                div [ style "height" "400px", style "margin-top" "25%", style "text-align" "center" ] [
                    h2 [] [ text "Fetching data from the server" ]
                    , Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
                ]
            Failure ->
                div [ style "height" "400px", style "margin-top" "25%", style "text-align" "center" ] [
                    h2 [] [ text "Profile failed to load" ]
                ]
            Success ->
                div[][
                    div[ class "jumbotron" ][
                        img [ class "avatar"
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
                                    span [ class "glyphicon glyphicon-ok-circle", style "color" "green", style "margin-left" "5px" ][]
                                else
                                    span [ class "glyphicon glyphicon-remove-circle", style "color" "red", style "margin-left" "5px" ] []
                        ]
                        , div [ style "margin-bottom" "20px" ] [
                            ul [ class "nav" ] [
                                case user.facebook of
                                    Just url ->
                                        Social.viewFacebook url
                                    Nothing ->
                                        div [][]
                                , case user.twitter of
                                    Just url ->
                                        Social.viewTwitter url
                                    Nothing ->
                                        div[][]
                                , case user.github of
                                    Just url ->
                                        Social.viewGithub url
                                    Nothing ->
                                        div [][]
                            ]
                        ]
                        , div [ style "font-style" "italic" ] [ text user.bio ]
                    ]
                    , if user.token /= "Hidden" then
                            ul [ class "nav nav-pills" ][
                                li [][ button [ if model.tab == Information then style "text-decoration" "underline" else style "" "", style "color" "black", onClick SwitchInformation ] [ {--span [ class " glyphicon glyphicon-info-sign" ][],--} text "Information"] ]
                                , li [][ button [ if model.tab == Settings then style "text-decoration" "underline" else style "" "", style "color" "black", onClick SwitchSettings ] [ text "Settings"] ]
                                , li [][ button [ if model.tab == Security then style "text-decoration" "underline" else style "" "", style "color" "black", onClick SwitchSecurity ] [ text "Security"] ]
                                , li [][ button [ if model.tab == History then style "text-decoration" "underline" else style "" "", style "color" "black", onClick SwitchHistory ] [ text "History"] ]
                            ]
                        else
                            text ""
                    , case model.tab of
                        Information ->
                            div[ class "list-group" ][
                                h3 [] [ text "Basic information" ]
                                , div [ class "help-block" ] [ text ("Here are some basic information about " ++ user.username) ]
                                , viewStringInfo user.firstName "First Name"
                                , viewStringInfo user.surname "Last Name"
                                , viewStringInfo user.occupation "Occupation"
                                , hr [] []
                                , h3 [] [ text "Account information" ]
                                , div [ class "help-block" ] [ text ("Here are some information about " ++ user.username ++ "'s account") ]
                                , text ("Registered at " ++ TimeFormat.formatTime user.registered)
                                , hr [][]
                                , h3 [] [ text "Post history" ]
                                , div [ class "help-block" ] [ text ("Preview of " ++ user.username ++ "'s posts") ]
                                , case model.posts of
                                    LoadingPost ->
                                        div [] [
                                            Loader.render Loader.Circle Loader.defaultConfig Loader.On
                                        ]
                                    FailurePost ->
                                        div [ class "alert alert-warning", style "width" "50%", style "margin" "auto" ] [ text "Connection error"]
                                    SuccessPost posts ->
                                        if List.isEmpty posts == True then
                                            div [ style "font-style" "italic" ] [ text "This user has no posts" ]
                                        else
                                            div [] (List.map viewPost posts)
                            ]
                        Settings ->
                            div [][ 
                                h3 [] [ text "Want to change your avatar?" ]
                                , div [ class "help-block" ] [ text "Upload a picture from your computer and make it your avatar! You can also click on your avatar!" ]
                                , button [ class "btn btn-primary", style "margin-bottom" "10px", onClick Select ] [ text "Select file" ]
                                , hr [] []
                                , h3 [] [ text "Update your bio" ]
                                , div [ class "help-block" ] [ text "Update the description others see on your profile"]
                                , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                                    div[][
                                        textarea [ cols 100, rows 10, id "bio", Html.Attributes.value model.bio, onInput Bio ] []
                                    ]
                                ] 
                                , hr [] []
                                , h3 [] [ text "Tell us more about yourself" ]  
                                , div [ class "help-block" ] [ text "Fill out the following information to complete your profile" ]  
                                , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                                    div [ class "col-md-offset-2 col-md-8" ] [
                                        div[ class "form-group has-feedback" ][
                                            label [ for "name" ] [ text "First Name:" ]
                                            , input [ id "name", type_ "text", class "form-control", Html.Attributes.value model.firstName, onInput FirstName ] []
                                        ]
                                    ]
                                ]
                                , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                                    div [ class "col-md-offset-2 col-md-8" ] [
                                        div[ class "form-group has-feedback" ][
                                            label [ for "lastname" ] [ text "Last Name:" ]
                                            , input [ id "lastname", type_ "text", class "form-control", Html.Attributes.value model.surname, onInput Surname ] []
                                        ]
                                    ]
                                ]
                                ,div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                                    div [ class "col-md-offset-2 col-md-8" ] [
                                        div[ class "form-group has-feedback" ][
                                            label [ for "occ" ] [ text "Occupation:" ]
                                            , input [ id "occ", type_ "text", class "form-control", Html.Attributes.value model.occupation, onInput Occupation ] []
                                        ]
                                    ]
                                ]
                                ,div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                                    div [ class "col-md-offset-2 col-md-8" ] [
                                        div[ class "form-group has-feedback" ][
                                            label [ for "mail" ] [ text "E-mail:" ]
                                            , input [ id "mail", disabled True, type_ "email", class "form-control", Html.Attributes.value user.email ] []
                                        ]
                                    ]
                                ]
                                , hr [] []
                                , h3 [] [ text "Link your social accounts" ]
                                , div [ class "help-block" ] [ text "Share your social accounts with our users!" ]
                                , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                                    div [ class "col-md-offset-2 col-md-8" ] [
                                        div[ class "form-group has-feedback" ][
                                            label [ for "fb" ] [ text "Link your Facebook:" ]
                                            , input [ id "fb", type_ "text", class "form-control", Html.Attributes.value model.facebook, onInput Facebook ] []
                                        ]
                                    ]
                                ]
                                ,div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                                    div [ class "col-md-offset-2 col-md-8" ] [
                                        div[ class "form-group has-feedback" ][
                                            label [ for "tw" ] [ text "Link your Twitter:" ]
                                            , input [ id "tw", type_ "text", class "form-control", Html.Attributes.value model.twitter, onInput Twitter ] []
                                        ]
                                    ]
                                ]
                                , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                                    div [ class "col-md-offset-2 col-md-8" ] [
                                        div[ class "form-group has-feedback" ][
                                            label [ for "git" ] [ text "Link your Github:" ]
                                            , input [ id "git", type_ "text", class "form-control", Html.Attributes.value model.github, onInput Github ] []
                                        ]
                                    ]
                                ]
                                , hr [] []
                                , h3 [] [ text "Update" ]
                                , div [ class "help-block" ] [ text "Save all changes to your basic information" ]
                                , button [ class "btn btn-primary", style "margin-bottom" "50px", onClick UpdateSettings ] [ text "Update Settings" ]
                            ]
                        Security ->
                            div[][
                                h3 [] [ text "Verify your account" ]
                                , div [ class "help-block" ] [ text "Verification is required for the completion of certain tasks"]
                                , case user.verif of
                                    False ->
                                        div[][
                                            viewVerify model
                                            , hr [] []
                                        ]
                                    _ -> 
                                        div[ class "alert alert-success", style "width" "20%", style "margin" "auto" ][ text "Your account is verified" ]
                                , hr [] []
                                , h3 [] [ text "Enable two-factor authentication?" ]
                                , div [ class "help-block" ] [ text "Make your account more secure by enabling two-factor verification" ]
                                , case user.verif of
                                    True ->
                                        button [ class "btn btn-success", style "margin-bottom" "15px", style "margin-top" "20px" ] [ text "Enable" ]                    
                                    False ->
                                        div [] [
                                            button [ class "btn btn-success", style "margin-bottom" "15px", style "margin-top" "20px", disabled True ] [ text "Enable" ]
                                            , div [ class "alert alert-warning", style "width" "20%", style "margin" "auto" ] [ text "You must verify your e-mail address first!" ]
                                        ]
                                , hr [] []
                                , h3 [] [ text "Want to change your password?" ]
                                , div [ class "help-block" ] [ text "Change your password by filling out the following form" ]
                                , div [ class "form-inline" ][
                                    div [ class "form-group row", style "padding-bottom" "15px" ] [ 
                                        div [ class "col-md-offset-2 col-md-8" ] [
                                            div[ class "form-group has-feedback" ][
                                                label [ for "old" ] [ text "Old Password:" ]
                                                , input [ id "old", type_ "password", class "form-control" ] []
                                            ]
                                        ]
                                    ]
                                    , div [ class "form-group row", style "padding-bottom" "15px" ] [ 
                                        div [ class "col-md-offset-2 col-md-8" ] [
                                            div[ class "form-group has-feedback" ][
                                                label [ for "new" ] [ text "New Password:" ]
                                                , input [ id "new", type_ "password", class "form-control" ] []
                                            ]
                                        ]
                                    ]
                                    , div [ class "form-group row", style "padding-bottom" "15px" ] [ 
                                        div [ class "col-md-offset-2 col-md-8" ] [
                                            div[ class "form-group has-feedback" ][
                                                label [ for "newA" ] [ text "New Password Again:" ]
                                                , input [ id "newA", type_ "password", class "form-control" ] []
                                            ]
                                        ]
                                    ]
                                ] 
                                , button [ class "btn btn-primary", style "margin-bottom" "10px", style "margin-top" "20px" ] [ text "Change Password" ]
                                , hr [] []
                                , h3 [] [ text "Delete my account" ]
                                , div [ class "help-block" ] [ text "Press the following button if you wish to permanently delete your account. This will also delete your posts and comments!"]
                                , button [ class "btn btn-danger", style "margin-bottom" "50px" ] [ text "Delete account" ]
                            ]   
                        History ->
                            div[ class "container", style "text-align" "center" ][ 
                                h3 [] [ text "Activity in the last month" ] 
                                , div [ class "help-block" ] [ text "This graph represents your image upload activity in the last month" ]
                                , div [ style "margin-left" "20%"] [ LineChart.view1 .x .y
                                    [ Point 1 2, Point 5 5, Point 10 10 ] ]
                                , hr [] []
                                , h3 [] [ text "My activity" ] 
                                , div [ class "help-block" ] [ text "This sections contains logs of your activity" ]
                            ]
                ]
    ]

viewPost: PostPreview -> Html Msg
viewPost post =
    div[ class "media"
    , style "width" "70%"
    , style "margin" "auto"
    , style "margin-bottom" "20px"  ][
        div[ class "media-left" ][
            a [ href ("/post/" ++ post.id) ][
                img [ src post.url
                , class "avatar"
                , height 100
                , width 100 ][]
            ]
        ]
        , div[ class "media-body well"
        , style "text-align" "left" ][
            div [ class "media-heading" ][
                div [ class "help-block" ] [
                    text (TimeFormat.formatTime post.uploaded)
                ]
            ]
            , div [ class "media-body" ][
                a [ href ("/post/" ++ post.id) ] [ text post.title ]
            ]
        ]
    ]

viewStringInfo: Maybe String -> String -> Html Msg
viewStringInfo attr name = 
    let 
        key = name ++ ": "
    in
        case attr of
            Just value ->
                div [ class "form-group row", style "width" "40%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                    div [ class "col-md-offset-2 col-md-8" ] [
                        div[ class "form-group has-feedback" ][
                            label [ for name ] [ text key ]
                            , input [ id name
                            , type_ "text"
                            , style "text-align" "center"
                            , readonly True, class "form-control"
                            , placeholder value
                            --, style "border" "none"
                            , style "background" "Transparent"
                            , style "outline" "none" ] []
                        ]
                    ]
                ]
            Nothing ->
                div [][]

viewVerify: Model -> Html Msg
viewVerify model =
  div [ class "form-horizontal fade in alert alert-info", id "form", style "margin" "auto", style "width" "75%" ] [
    h2 [ class "text-center" ] [ text "Verify your e-mail address" ]
    , div [ class "help-block" ] [ text ("Your account is not verified. We will send a verification mail to " ++ model.user.email) ]
    , button [ class "btn btn-primary", style "margin-bottom" "10px", onClick Request ] [ text "Send me the code" ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ] [
          div[][ 
                div[ class "form-group" ][
                  label [ for "verify" ] [ text "Enter the received code:" ]
                  , input [ id "verify", type_ "code", class "form-control", Html.Attributes.value model.code, onInput Code ] []
                  , button [ class "btn btn-primary", style "margin-top" "10px", onClick Verify ][ text "Verify" ]
                ]
          ]
        ]
    ]
  ]

emailEncoder: String -> Encode.Value
emailEncoder email =
  Encode.object
  [ ( "email", Encode.string email )
  ]

codeEncoder: Model -> Encode.Value
codeEncoder model =
    Encode.object
    [
        ("verifCode", Encode.string model.code )
        , ( "username", Encode.string model.user.username)
    ]

requestMail: String -> Cmd Msg
requestMail email = 
    Http.post {
      url = Server.url ++ "/mailer/send"
      , body = Http.jsonBody <| emailEncoder email
      , expect = Http.expectWhatever MailResponse
    }

verifyCode: Model -> Cmd Msg
verifyCode model =
    Http.post {
      url = Server.url ++ "/account/verify"
      , body = Http.jsonBody <| codeEncoder model
      , expect = Http.expectJson VerifyResponse (field "response" Decode.bool)
    }

stringEncoder: String -> String -> Encode.Value
stringEncoder key value =
    Encode.object [(key, Encode.string value)]

settingsEncoder: Model -> Encode.Value
settingsEncoder model =
    Encode.object 
        [
            ("firstName", Encode.string model.firstName)
            , ("surname", Encode.string model.surname)
            , ("occupation", Encode.string model.occupation)
            , ("facebook", Encode.string model.facebook)
            , ("twitter", Encode.string model.twitter)
            , ("github", Encode.string model.github)
            , ("bio", Encode.string model.bio)
        ]

decodePostPreview: Decode.Decoder PostPreview
decodePostPreview =
    Decode.succeed PostPreview
        |> required "title" Decode.string 
        |> required "uploaded" DecodeExtra.datetime
        |> required "id" Decode.string
        |> required "file" Decode.string 


getPosts: String -> Cmd Msg
getPosts username =
    Http.request
    {
        method = "POST"
        , headers = []
        , url = Server.url ++ "/account/posts"
        , body = Http.jsonBody <| (stringEncoder "username" username)
        , expect = Http.expectJson PostsResponse (Decode.list decodePostPreview)
        , timeout = Nothing
        , tracker = Nothing
    }

put : File -> String -> Cmd Msg
put file user = 
  Http.request
    { method = "PUT"
    , headers = [ Http.header "name" (File.name file), Http.header "user" user ]
    , url = Server.url ++ "/upload/profile"
    , body = Http.fileBody file 
    , expect = Http.expectJson AvatarResponse ( field "response" Decode.string )
    , timeout = Nothing
    , tracker = Nothing
    }

loadUser: String -> Cmd Msg
loadUser username = 
  Http.request
    { method = "POST"
    , headers = []
    , url = Server.url ++ "/account/user"
    , body = Http.jsonBody <| (stringEncoder "username" username)
    , expect = Http.expectJson Response User.decodeUserNotLoggedIn
    , timeout = Nothing
    , tracker = Nothing
    }

patch: Model -> String -> Cmd Msg
patch model token =
    Http.request
    {
        method = "PATCH"
        , headers = [ Http.header "auth" token ]
        , url = Server.url ++ "/account/update"
        , body = Http.jsonBody <| settingsEncoder model
        , expect = Http.expectWhatever UpdateResponse
        , timeout = Nothing
        , tracker = Nothing
    }
