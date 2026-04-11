import Foundation

struct RGB {
    let r: Double
    let g: Double
    let b: Double
}

struct Preset: Identifiable {
    let id: String
    let name: String
    let kelvin: Double
}

func kelvinToRGB(_ kelvin: Double) -> RGB {
    let temperature = kelvin / 100
    var red: Double
    var green: Double
    var blue: Double

    if temperature <= 66 {
        red = 255
        green = 99.4708025861 * log(temperature) - 161.1195681661
        if temperature <= 19 {
            blue = 0
        } else {
            blue = 138.5177312231 * log(temperature - 10) - 305.0447927307
        }
    } else {
        red = 329.698727446 * pow(temperature - 60, -0.1332047592)
        green = 288.1221695283 * pow(temperature - 60, -0.0755148492)
        blue = 255
    }

    return RGB(
        r: min(max(red, 0), 255) / 255,
        g: min(max(green, 0), 255) / 255,
        b: min(max(blue, 0), 255) / 255
    )
}
