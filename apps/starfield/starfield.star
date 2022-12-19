"""
Applet: Starfield
Summary: Fly through a starfield
Description: This app simulates flying through a starfield.
Author: gabe565
"""

load("math.star", "math")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

WIDTH = 64
HEIGHT = 32
DELAY = 50
FRAMES = 300

CENTER_X = int(WIDTH / 2)
CENTER_Y = int(HEIGHT / 2)

MIN_RADIUS = 4
MAX_RADIUS = 38.5

DEFAULT_BACKGROUND_COLOR = 0
BACKGROUND_COLORS = [
    schema.Option(
        display = "Dark Blue",
        value = "#000013",
    ),
    schema.Option(
        display = "Black",
        value = "#000",
    ),
]

DEFAULT_STAR_COLOR = 0
STAR_COLORS = [
    schema.Option(
        display = "White",
        value = "#FFF",
    ),
    schema.Option(
        display = "Yellow",
        value = "#FF0",
    ),
    schema.Option(
        display = "Red",
        value = "#F44",
    ),
    schema.Option(
        display = "Blue",
        value = "#77F",
    ),
    schema.Option(
        display = "Green",
        value = "#0F0",
    ),
    schema.Option(
        display = "Orange",
        value = "#FFA500",
    ),
]
DEFAULT_USE_CUSTOM_STAR_COLOR = False
DEFAULT_CUSTOM_STAR_COLOR = ""

DEFAULT_STAR_COUNT = 1
STAR_COUNTS = [
    schema.Option(
        display = "10",
        value = "10",
    ),
    schema.Option(
        display = "25 (Default)",
        value = "25",
    ),
    schema.Option(
        display = "40",
        value = "40",
    ),
    schema.Option(
        display = "50",
        value = "50",
    ),
    schema.Option(
        display = "60",
        value = "60",
    ),
]

DEFAULT_TAIL_LENGTH = 2
TAIL_LENGTHS = [
    schema.Option(
        display = "Disabled",
        value = "0",
    ),
    schema.Option(
        display = "Shorter",
        value = "1",
    ),
    schema.Option(
        display = "Regular",
        value = "1.5",
    ),
    schema.Option(
        display = "Longer",
        value = "2",
    ),
]

DEFAULT_SPEED = 2
SPEEDS = [
    schema.Option(
        display = "Slowest",
        value = "0.2",
    ),
    schema.Option(
        display = "Slower",
        value = "0.5",
    ),
    schema.Option(
        display = "Regular",
        value = "1",
    ),
    schema.Option(
        display = "Faster",
        value = "1.3",
    ),
    schema.Option(
        display = "Fastest",
        value = "2",
    ),
]

def main(config):
    stars = make_stars(config)

    star_color = get_star_color_config(config)
    if star_color == None:
        return render.Root(
            child = render.WrappedText(
                content = "Invalid star color",
            ),
        )

    frames = []
    for i in range(FRAMES):
        frames.append(render_frame(config, stars, star_color))

    return render.Root(
        delay = DELAY,
        child = render.Stack(
            children = [
                render.Box(
                    color = config.get("background_color", BACKGROUND_COLORS[DEFAULT_BACKGROUND_COLOR].value),
                ),
                render.Animation(
                    children = frames,
                ),
            ],
        ),
    )

def random_angle():
    """
    Returns a random value between 0 and 2*pi.
    Multiplies by 2, then divides by 2 so that half angles can be included, even though random.number only accepts ints.
    """
    return math.radians(random.number(0, 359 * 2) / 2)

def random_radius():
    """Returns a random value between MIN_RADIUS and MAX_RADIUS."""
    return random.number(MIN_RADIUS, int(MAX_RADIUS))

def random_speed(config):
    """Returns a random value from 0.25 to 2 at 0.25 increments, multiplied by the current speed."""
    speed = float(config.get("star_speed", SPEEDS[DEFAULT_SPEED].value))
    return random.number(1, 8) / 4 * speed

def make_stars(config):
    """
    Creates a list of stars. Each star is represented as a point on a circle with an angle, radius, and speed.
    Each frame, radius will increase by the speed value to simulate movement.
    """
    count = int(config.get("star_count", STAR_COUNTS[DEFAULT_STAR_COUNT].value))

    stars = []
    for i in range(count):
        stars.append({
            "angle": random_angle(),
            "radius": random_radius(),
            "speed": random_speed(config),
        })
    return stars

def render_frame(config, stars, star_color):
    """Iterates over every star, moving each one then rendering a frame."""
    streak_length = float(config.get("star_tail_length", DEFAULT_TAIL_LENGTH))

    children = []
    for star in stars:
        move_star(star)

        # Render star
        radius = star["radius"]
        x, y, ok = get_star_xy(radius, star["angle"])
        if ok:
            color = star_color + get_alpha(radius)
            children.append(render_pixel(x, y, color))

        # Render trail
        for i in range(int(star["speed"] * streak_length)):
            tail_radius = radius - i
            if tail_radius < MIN_RADIUS:
                break
            x, y, ok = get_star_xy(tail_radius, star["angle"])
            if ok:
                color = star_color + get_alpha(radius)
                children.append(render_pixel(x, y, color))

        # Reset when star and trail is out of bounds
        if not ok:
            reset_star(config, star)

    return render.Stack(
        children = children,
    )

def render_pixel(x, y, color):
    """Renders a pixel by adding padding to a box."""
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Box(
            color = color,
            width = 1,
            height = 1,
        ),
    )

def get_star_xy(radius, angle):
    """
    Gets the current x, y value based on the angle and radius, then centers to the axis.
    The third variable will return true if the star is still within the frame.
    """
    x = int(math.sin(angle) * radius + CENTER_X)
    y = int(math.cos(angle) * radius + CENTER_Y)
    ok = 0 <= x and x < WIDTH and 0 <= y and y < HEIGHT
    return x, y, ok

def reset_star(config, star):
    """Move the star back to the center at a new random position."""
    star["angle"] = random_angle()
    star["radius"] = MIN_RADIUS
    star["speed"] = random_speed(config)

def move_star(star):
    star["speed"] += 0.1
    star["radius"] += star["speed"]

def get_alpha(radius):
    """Converts from radius (0-38) to hex alpha value (0x00-0xFF)"""
    alpha = radius * 0xFF / MAX_RADIUS
    if alpha > 255:
        alpha = 255
    hex = ("0%X" % alpha)[-2:]
    return hex

def get_star_color_config(config):
    """Gets either the chosen color or the custom color. Custom colors are validated, and all colors are sanitized."""
    if config.bool("use_custom_star_color", DEFAULT_USE_CUSTOM_STAR_COLOR):
        star_color = config.get("custom_star_color", DEFAULT_CUSTOM_STAR_COLOR)
        if not valid_color(star_color):
            return None
    else:
        star_color = config.get("star_color", STAR_COLORS[DEFAULT_STAR_COLOR].value)

    return sanitize_color(star_color)

def valid_color(color):
    """Validates hex color"""
    match = re.findall("^#[0-9a-fA-F]{8}$|#[0-9a-fA-F]{6}$|#[0-9a-fA-F]{4}$|#[0-9a-fA-F]{3}$", color)
    return len(match) == 1

def sanitize_color(color):
    """
    Sanitizes color values.
    Tidbyt supports multiple color formats, but since an alpha value will be appended, we need the star color to be
    in the #FFFFFF syntax.
    """
    if len(color) == 5:
        # Remove shorthand alpha value (#FFFF to #FFF)
        color = color[:-1]
    if len(color) == 4:
        # Expand shorthand (#FFF to #FFFFFF)
        return "#" + 2 * color[1] + 2 * color[2] + 2 * color[3]

    # Remove alpha (#FFFFFFFF to #FFFFFF)
    return color[:7]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "background_color",
                name = "Background Color",
                desc = "Change the background color",
                icon = "palette",
                default = BACKGROUND_COLORS[DEFAULT_BACKGROUND_COLOR].value,
                options = BACKGROUND_COLORS,
            ),
            schema.Dropdown(
                id = "star_color",
                name = "Star Color",
                desc = "Change the color of the stars",
                icon = "palette",
                default = STAR_COLORS[DEFAULT_STAR_COLOR].value,
                options = STAR_COLORS,
            ),
            schema.Toggle(
                id = "use_custom_star_color",
                name = "Use Custom Star Color?",
                desc = "Enables star custom color",
                icon = "palette",
                default = DEFAULT_USE_CUSTOM_STAR_COLOR,
            ),
            schema.Text(
                id = "custom_star_color",
                name = "Custom Star Color",
                desc = "Hex code for custom star color",
                icon = "palette",
                default = DEFAULT_CUSTOM_STAR_COLOR,
            ),
            schema.Dropdown(
                id = "star_count",
                name = "Number of Stars",
                desc = "Change the number of stars",
                icon = "hashtag",
                default = STAR_COUNTS[DEFAULT_STAR_COUNT].value,
                options = STAR_COUNTS,
            ),
            schema.Dropdown(
                id = "star_speed",
                name = "Star Speed",
                desc = "Changes the star speed",
                icon = "personRunning",
                default = SPEEDS[DEFAULT_SPEED].value,
                options = SPEEDS,
            ),
            schema.Dropdown(
                id = "star_tail_length",
                name = "Star Tail Length",
                desc = "Changes the star tail length",
                icon = "ruler",
                default = TAIL_LENGTHS[DEFAULT_TAIL_LENGTH].value,
                options = TAIL_LENGTHS,
            ),
        ],
    )