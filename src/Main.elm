module Main exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Url
import Url.Parser as Parser exposing (Parser, (</>), custom, fragment, map, oneOf, s, top)
import Json.Decode as Json
import FeatherIcons as Icons
import Pages.Gallery as Gallery
import Pages.SignUp as SignUp
import Pages.SignIn as SignIn
import Components.SearchBar as Search
import Components.Carousel as Carousel
--import Components.SingUp as SignUp

--usage - type the following command into terminal (need to install elm-live)
--elm-live src/Main.elm --open -- --output=elm.js (will start server on localhost)

-- MAIN

main : Program () Model Msg
main =
  Browser.application
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , onUrlChange = UrlChange
    , onUrlRequest = UrlRequest
    }



-- MODEL

type alias Model =
  { key : Nav.Key
  , url : Url.Url
  , page : Page
  , search : Search.Model
  , carousel : Carousel.Model
  }

type Page 
  = NotFound
  | Gallery Gallery.Model
  | Forum
  | Profile
  | SignUp SignUp.Model
  | SignIn SignIn.Model

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ({ key = key
    , url = url
    , page = NotFound
    , search = Search.init
    , carousel = Carousel.init
    }, Cmd.none)
    

type Msg
  = UrlRequest Browser.UrlRequest
  | UrlChange Url.Url
  | GalleryMsg Gallery.Msg  --converter types
  | SignUpMsg SignUp.Msg
  | SignInMsg SignIn.Msg
  | UpdateSearch Search.Msg
  | UpdateCarousel Carousel.Msg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UrlRequest urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Nav.pushUrl model.key (Url.toString url) )

        Browser.External href ->
          ( model, Nav.load href )

    UrlChange url ->
      stepUrl url model
      --( { model | url = url}
      --, Cmd.none
      --)
    UpdateSearch mesg -> 
       ({ model | search = Search.update mesg model.search }, Cmd.none)
    UpdateCarousel mesg -> 
       ({ model | carousel = Carousel.update mesg model.carousel }, Cmd.none)
    SignUpMsg mesg ->
      case model.page of
        SignUp signup ->
          ({model | page = SignUp (SignUp.update mesg signup)}, Cmd.none)
          --       -> (model, Cmd.none)
        _ -> (model, Cmd.none)
    SignInMsg mesg ->
      case model.page of
        SignIn signin ->
          ({model | page = SignIn (SignIn.update mesg signin)}, Cmd.none)
        _ -> (model, Cmd.none)
    GalleryMsg mesg ->
      case model.page of
        Gallery gallery -> stepGallery model (Gallery.update mesg gallery)
        _ -> ( model, Cmd.none )


stepSignUp : Model -> (SignUp.Model, Cmd SignUp.Msg) -> (Model, Cmd Msg)
stepSignUp model (signup, cmd) =
  ({ model | page = SignUp signup }, Cmd.map SignUpMsg cmd)

stepSignIn : Model -> (SignIn.Model, Cmd SignIn.Msg) -> (Model, Cmd Msg)
stepSignIn model (signin, cmd) = 
  ({ model | page = SignIn signin }, Cmd.map SignInMsg cmd)

stepGallery : Model -> (Gallery.Model, Cmd Gallery.Msg) -> (Model, Cmd Msg)
stepGallery model (gallery, cmd) = 
  ({ model | page = Gallery gallery } , Cmd.map GalleryMsg cmd)

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  if model.page == NotFound
  then
    Carousel.subscriptions model.carousel |> Sub.map UpdateCarousel
  else
    Sub.none
  --Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
  case model.page of
    NotFound ->
      { title = "Elm Web Application"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        , viewBody model
        , viewFooter
        ]
      }
    Gallery gallery ->
      { title = "Gallery"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        , Gallery.view gallery |> Html.map GalleryMsg
        , viewFooter        
        ]
      }
    Forum ->
      { title = "Forum"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        , viewBody model
        , viewFooter
        ]
      }
    Profile ->
      { title = "Profile"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        --, viewBody model
        , viewFooter
        ]
      }
    SignUp signup ->
      { title = "Sign up"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        , div[class "body"][
         SignUp.view signup |> Html.map SignUpMsg
        ]
        , viewFooter
        ]
      }
    SignIn signin ->
      { title = "Sign in"
      , body = [
        --[ text "URL is: "
        --, b [style "color" "orange"] [ text (Url.toString model.url) ]
        viewHeader model
        , div[class "body"][
         SignIn.view signin |> Html.map SignInMsg
        ]
        --, viewBody model
        , viewFooter
        ]
      }


viewImage : String -> Int -> Int -> Html msg
viewImage path w h =
  img[src path, width w, height h] []

viewHeader: Model -> Html Msg
viewHeader model =
    div [] [
    {--
    div [class "header"]
    [
        h1 [] [
          div[style "display" "inline"
              , style "margin-right" "10px"]
          [
          viewImage "../src/img/Elm_logo.svg.png" 70 70
          ]
          , a [ href "/" ] [ text "Elm prototype" ]--}
          viewNav{--
        ]
        , Search.view model.search |> Html.map UpdateSearch
        , div [class "login"][
          a [ href "/sign_up" ] [ text "Sign up" ]
          , text " "
          , a [ href "/sign_in" ] [ text "Sign in" ]
        ]--}
    ]

viewNav: Html msg
viewNav = 
  div [ class "navbar navbar-inverse navbar-fixed-top" ]
    [ 
      div [ class "container-fluid"][
        div [ class "navbar-header"][
          div [ class "navbar-brand"][ 
            viewImage "../src/img/Elm_logo.svg.png" 35 35 
            ]
        ]
        , ul [ class "nav navbar-nav"][
            li [] [ a [ href "/" ] [ text "Home"] ]
            , li [] [ a [ href "/gallery" ] [ text "Gallery" ] ]
            , li [] [ a [href "/gallery" ] [text "Upload Image"] ]
            , li [] [ a [ href "/forum" ] [ text "Forum" ] ]
            , li [] [ a [ href "/profile" ] [ text "Profile" ] ]
        ]
        , ul [ class "nav navbar-nav navbar-right"][
            li [] [ a [ href "/sign_in"] [ span [class "glyphicon glyphicon-user"][], text " Sign In"] ]
            , li [] [ a [ href "/sign_up"] [ span [class "glyphicon glyphicon-user"][], text " Sign Up"] ]
          ]
      ]
    ]

viewBody: Model -> Html Msg
viewBody model =
  div [ class "body" ]
  [
    h2[][text "Welcome to my website"]
    , p[][text "Loourem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sed condimentum risus, congue dignissim augue. Nulla rhoncus ullamcorper luctus. Ut enim felis, tincidunt at euismod vel, consequat a diam. Donec eu egestas urna. Vivamus arcu nisi, eleifend sed turpis id, faucibus varius lectus. Integer viverra quis est sed vulputate. Quisque lacinia sagittis mollis. Nulla facilisi. Integer arcu augue, sollicitudin id ultricies a, sagittis nec dui. Nulla quis justo mattis, sagittis nisl et, auctor mauris. Mauris ac metus in neque blandit euismod. Duis quam elit, congue sed egestas ornare, euismod id lectus. Integer eget tortor a erat semper facilisis. Aliquam erat volutpat. Nulla sollicitudin, ante nec semper pharetra, nisl arcu aliquam sapien, a eleifend magna turpis eu sapien. Fusce ullamcorper dictum purus, sed faucibus tellus euismod quis. Cras vestibulum, ipsum quis cursus dictum, enim orci venenatis est, et aliquet odio est sit amet ante. Nam erat eros, efficitur id sodales id, egestas nec lacus. Maecenas vulputate tincidunt elit, a lobortis dolor molestie id. Vestibulum eu sagittis quam. Vivamus felis nisi, rhoncus quis fermentum id, lobortis a ipsum. Ut celerisque viverra venenatis. Maecenas porta aliquet urna non ullamcorper. Mauris nec faucibus arcu. Aenean mattis ornare hendrerit. Praesent ut sem ex. Cras lobortis dapibus bibendum. Nam malesuada pulvinar sem, eu aliquam sem dignissim molestie. Morbi lobortis ultrices quam id laoreet. Nam ullamcorper quam egestas risus aliquet, ut pretium ante suscipit. Suspendisse neque lacus, aliquet non sem nec, sagittis aliquet massa. Donec vel odio erat. Proin venenatis, arcu id mollis tincidunt, mi nunc facilisis dui, finibus blandit arcu justo vel purus. Nullam mollis orci vitae augue ultricies tempus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Sed at tempus urna. Ut vitae placerat sapien."]
    , div[class "carousel"][Carousel.view model.carousel |> Html.map UpdateCarousel]
  ]

--viewSignUpForm: Model -> Html Msg
--viewBody model =

viewFooter: Html Msg
viewFooter =
  div[style "background-color" "white"
  , style "height" "100px"
  , style "text-align" "center"
  , style "padding-top" "35px"
  , class "footer"]
  [ text "© 2019 Juraj Bedej   "
  , a [ href "https://github.com/jaruji?tab=repositories"] [ text "Github"
    --Icons.github
    --|> Icons.withSize 20
    --|> Icons.toHtml []
    ]
  ]

--Router

stepUrl : Url.Url -> Model -> (Model, Cmd Msg)
stepUrl url model =
  let
    parser =
      oneOf   --rerouting based on url change!
        [ route (s "gallery")
            ( stepGallery model (Gallery.init)
            )
          , route (s "forum")
            ( stepGallery model (Gallery.init)
            )
          , route (s "profile")
            ( stepGallery model (Gallery.init)
            )
          , route (s "sign_up")
            ( stepSignUp model (SignUp.init)
            )
          , route (s "sign_in")
            ( stepSignIn model (SignIn.init)
            )
        ]
  in 
  case Parser.parse parser url of
    Just urll ->
      urll

    Nothing ->
      ({model | page = NotFound}, Cmd.none)

route : Parser a b -> a -> Parser (b -> c) c
route parser handler =
  Parser.map handler parser