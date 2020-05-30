module Social exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import FeatherIcons as Icons

--this module contains the views for social buttons

viewFacebook: String -> Html msg
viewFacebook url =
    a [ href url ] [
        button [ class "btn btn-primary social"
                 , style "height" "50px"
                 , style "width" "50px"
                 , style "border-radius" "50%"
                 , style "background-color" "#3b5998"
                 , style "margin-left" "5px"
                 , style "margin-right" "5px" 
                 , style "border" "0px solid"
                 , style "box-shadow" "0px 12px 15px rgba(0, 0, 0, 0.4)"
                 , style "transition" "all 0.3s ease 0s"
                 , style "outline" "none"
        ] [ Icons.facebook |> Icons.withSize 25 |> Icons.toHtml [] ]
    ]

viewTwitter: String -> Html msg
viewTwitter url =
    a [ href url ] [
        button [ class "btn btn-primary social"
                 , style "height" "50px"
                 , style "width" "50px"
                 , style "border-radius" "50%"
                 , style "background-color" "#00acee" 
                 , style "margin-left" "5px"
                 , style "margin-right" "5px" 
                 , style "border" "0px solid"
                 , style "box-shadow" "0px 12px 15px rgba(0, 0, 0, 0.4)"
                 , style "transition" "all 0.3s ease 0s"
                 , style "outline" "none"
        ] [ Icons.twitter |> Icons.withSize 25 |> Icons.toHtml [] ]
    ]

viewGithub: String -> Html msg
viewGithub url =
    a [ href url ] [
        button [ class "btn btn-primary social"
                 , style "height" "50px"
                 , style "width" "50px"
                 , style "border-radius" "50%"
                 , style "background-color" "#211F1F" 
                 , style "margin-left" "5px"
                 , style "margin-right" "5px"
                 , style "border" "0px solid" 
                 , style "box-shadow" "0px 12px 15px rgba(0, 0, 0, 0.4)"
                 , style "transition" "all 0.3s ease 0s"
                 , style "outline" "none"
        ] [ Icons.github |> Icons.withSize 25 |> Icons.toHtml [] ]
    ]

--function that attempts to validate, if the url of social function is valid
validate: String -> String -> Bool
validate url social =
    if ( String.startsWith "http" url && String.contains social url && String.contains ".com" url) 
    || url == "" then
        True
    else
        False

getLink: Maybe String -> String
getLink link =
    case link of
        Nothing ->
            ""
        Just url ->
            url