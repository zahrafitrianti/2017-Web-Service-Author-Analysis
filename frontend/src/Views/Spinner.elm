module Views.Spinner exposing (spinner)

import Html exposing (Html, Attribute, div, li)
import Html.Attributes exposing (class, style)
import Utils exposing ((=>))


{-| A small loading animation
-}
spinner : Html msg
spinner =
    li [ class "sk-three-bounce", style ([ "margin" => "8px", "list-style-type" => "none" ]) ]
        [ div [ class "sk-child sk-bounce1" ] []
        , div [ class "sk-child sk-bounce2" ] []
        , div [ class "sk-child sk-bounce3" ] []
        ]
