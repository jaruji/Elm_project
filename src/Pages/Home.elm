module HomePage exposing (main)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
--import Components.SearchBar as SearchBar exposing(..)
--import Components.Carousel as Carousel exposing (..)
--import Animation exposing (px)
--import Element exposing (Element, el, row, alignRight, fill,rgb255, spacing, centerY, padding)
--import Element.Background as Background
--import Element.Border as Border
--import Element.Font as Font

--Model

type alias Model =
  {
    --search: SearchBar.Search
    --, carousel: Carousel.Model
    value1: String
  }

init : Model
init =
  {
    --search = SearchBar.init
    --, carousel = Carousel.init
    value1 = ""
  }

--Update

type Msg
    = ChangeOne String

update : Msg -> Model -> Model
update msg model =
  case msg of
    ChangeOne val ->
      ({model | value1 = val})

--View

view: Model -> Html Msg
view model =
  div [style "display" "block"]
  [
    viewHeader model
    , viewBody model
    , viewFooter model
  ]

viewHeader: Model -> Html Msg
viewHeader model =
    div [class "header"]
    [
        h1 [] [
          div[style "display" "inline"
              , style "margin-right" "10px"]
          [
          img[src "src/img/Elm_logo.svg.png", width 80, height 80] []
          ]
          , text "Elm prototype"
        ]
        ,div [class "login"][
          button [][text "Sign up"]
          , button [][text "Sign in"]
        ]
    ]

viewBody: Model -> Html Msg
viewBody model =
  div [style "background-color" "#2E86C1"
  , style "height" "1000px"
  , style "padding-top" "110px"
  , style "text-align" "center"
  , style "color" "black"]
  [
    h2[][text "Hello World"]
    , p[][text "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sed condimentum risus, congue dignissim augue. Nulla rhoncus ullamcorper luctus. Ut enim felis, tincidunt at euismod vel, consequat a diam. Donec eu egestas urna. Vivamus arcu nisi, eleifend sed turpis id, faucibus varius lectus. Integer viverra quis est sed vulputate. Quisque lacinia sagittis mollis. Nulla facilisi. Integer arcu augue, sollicitudin id ultricies a, sagittis nec dui. Nulla quis justo mattis, sagittis nisl et, auctor mauris. Mauris ac metus in neque blandit euismod. Duis quam elit, congue sed egestas ornare, euismod id lectus. Integer eget tortor a erat semper facilisis. Aliquam erat volutpat. Nulla sollicitudin, ante nec semper pharetra, nisl arcu aliquam sapien, a eleifend magna turpis eu sapien. Fusce ullamcorper dictum purus, sed faucibus tellus euismod quis. Cras vestibulum, ipsum quis cursus dictum, enim orci venenatis est, et aliquet odio est sit amet ante. Nam erat eros, efficitur id sodales id, egestas nec lacus. Maecenas vulputate tincidunt elit, a lobortis dolor molestie id. Vestibulum eu sagittis quam. Vivamus felis nisi, rhoncus quis fermentum id, lobortis a ipsum. Ut celerisque viverra venenatis. Maecenas porta aliquet urna non ullamcorper. Mauris nec faucibus arcu. Aenean mattis ornare hendrerit. Praesent ut sem ex. Cras lobortis dapibus bibendum. Nam malesuada pulvinar sem, eu aliquam sem dignissim molestie. Morbi lobortis ultrices quam id laoreet. Nam ullamcorper quam egestas risus aliquet, ut pretium ante suscipit. Suspendisse neque lacus, aliquet non sem nec, sagittis aliquet massa. Donec vel odio erat. Proin venenatis, arcu id mollis tincidunt, mi nunc facilisis dui, finibus blandit arcu justo vel purus. Nullam mollis orci vitae augue ultricies tempus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Sed at tempus urna. Ut vitae placerat sapien."]
  ]

viewFooter: Model -> Html Msg
viewFooter model =
  div[style "background-color" "white"
  , style "height" "100px"
  , style "text-align" "center"
  , style "padding-top" "35px"]
   [  text "© 2019 Juraj Bedej"
    ]

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


--Main

main =
  Browser.document
    { init = \() -> ( init, Cmd.none )
    , update = \msg model -> ( update msg model, Cmd.none )
    , subscriptions = subscriptions
    , view = \model ->
        { title = "Elm prototype"
        , body =
            [
              view model
            ]
        }
      --, onUrlChange =
      --, onUrlRequest =
    }
