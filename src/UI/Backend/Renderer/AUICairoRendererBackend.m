#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import "UI/Backend/Renderer/AUICairoRendererBackend.h"
#import "UI/AUIBackend.h"
#import "UI/AUIClaySupport.h"
#import "UI/AUIInternal.h"

#pragma clang assume_nonnull begin

typedef enum AUIRendererCairoBorderSide {
    AUIRendererCairoBorderTop,
    AUIRendererCairoBorderRight,
    AUIRendererCairoBorderBottom,
    AUIRendererCairoBorderLeft
} AUIRendererCairoBorderSide;

static cairo_t *nillable AUICairoRendererCurrentContext = nullptr;
static char *_Nonnull async_ui_cairo_fonts[] = {
    (char *)"Sans"
};

static inline double AUIRendererCairoChannel(uint8_t value)
{
    return ((double)value) / 255.0;
}

static inline void AUIRendererCairoSetSourceColor(cairo_t *cr, Clay_Color color)
{
    cairo_set_source_rgba(cr,
                          AUIRendererCairoChannel(color.r),
                          AUIRendererCairoChannel(color.g),
                          AUIRendererCairoChannel(color.b),
                          AUIRendererCairoChannel(color.a));
}

static inline double AUIRendererCairoClampRadius(double radius, Clay_BoundingBox bb)
{
    double maxRadius = fmax(0.0, fmin(bb.width, bb.height) / 2.0);

    if (radius < 0.0)
        return 0.0;
    if (radius > maxRadius)
        return maxRadius;
    return radius;
}

static char *nillable AUIRendererCairoCopyUTF8String(Clay_StringSlice text)
{
    char *copy = malloc((size_t)text.length + 1);

    if (copy == nullptr)
        return nullptr;

    memcpy(copy, text.chars, (size_t)text.length);
    copy[text.length] = '\0';
    return copy;
}

static char *AUIRendererCairoFontFamily(char *const *fonts, uint16_t fontID)
{
    if (fonts == nullptr)
        return (char *)"Sans";

    return (fonts[fontID] != nullptr ? fonts[fontID] : (char *)"Sans");
}

static void AUIRendererCairoAddRoundedRect(cairo_t *cr, Clay_BoundingBox bb, Clay_CornerRadius radius)
{
    double topLeft = AUIRendererCairoClampRadius(radius.topLeft, bb);
    double topRight = AUIRendererCairoClampRadius(radius.topRight, bb);
    double bottomRight = AUIRendererCairoClampRadius(radius.bottomRight, bb);
    double bottomLeft = AUIRendererCairoClampRadius(radius.bottomLeft, bb);

    cairo_new_sub_path(cr);
    cairo_move_to(cr, bb.x + topLeft, bb.y);
    cairo_line_to(cr, bb.x + bb.width - topRight, bb.y);

    if (topRight > 0.0)
        cairo_arc(cr, bb.x + bb.width - topRight, bb.y + topRight, topRight, 3.0 * M_PI / 2.0, 2.0 * M_PI);
    else
        cairo_line_to(cr, bb.x + bb.width, bb.y);

    cairo_line_to(cr, bb.x + bb.width, bb.y + bb.height - bottomRight);

    if (bottomRight > 0.0)
        cairo_arc(cr, bb.x + bb.width - bottomRight, bb.y + bb.height - bottomRight, bottomRight, 0.0, M_PI / 2.0);
    else
        cairo_line_to(cr, bb.x + bb.width, bb.y + bb.height);

    cairo_line_to(cr, bb.x + bottomLeft, bb.y + bb.height);

    if (bottomLeft > 0.0)
        cairo_arc(cr, bb.x + bottomLeft, bb.y + bb.height - bottomLeft, bottomLeft, M_PI / 2.0, M_PI);
    else
        cairo_line_to(cr, bb.x, bb.y + bb.height);

    cairo_line_to(cr, bb.x, bb.y + topLeft);

    if (topLeft > 0.0)
        cairo_arc(cr, bb.x + topLeft, bb.y + topLeft, topLeft, M_PI, 3.0 * M_PI / 2.0);
    else
        cairo_line_to(cr, bb.x, bb.y);

    cairo_close_path(cr);
}

static void AUIRendererCairoRenderRectangle(cairo_t *cr, Clay_RectangleRenderData *config, Clay_BoundingBox bb)
{
    AUIRendererCairoSetSourceColor(cr, config->backgroundColor);
    AUIRendererCairoAddRoundedRect(cr, bb, config->cornerRadius);
    cairo_fill(cr);
}

static void AUIRendererCairoRenderBorderSide(cairo_t *cr,
                                             Clay_BoundingBox bb,
                                             Clay_BorderRenderData *config,
                                             double topLeft,
                                             double topRight,
                                             double bottomRight,
                                             double bottomLeft,
                                             AUIRendererCairoBorderSide side)
{
    AUIRendererCairoSetSourceColor(cr, config->color);
    cairo_new_sub_path(cr);

    switch (side) {
        case AUIRendererCairoBorderTop:
            cairo_move_to(cr, bb.x, bb.y + topLeft);
            if (topLeft > 0.0)
                cairo_arc(cr, bb.x + topLeft, bb.y + topLeft, topLeft, M_PI, 3.0 * M_PI / 2.0);
            else
                cairo_line_to(cr, bb.x, bb.y);
            cairo_line_to(cr, bb.x + bb.width - topRight, bb.y);
            if (topRight > 0.0)
                cairo_arc(cr, bb.x + bb.width - topRight, bb.y + topRight, topRight, 3.0 * M_PI / 2.0, 2.0 * M_PI);
            else
                cairo_line_to(cr, bb.x + bb.width, bb.y);
            break;
        case AUIRendererCairoBorderRight:
            cairo_move_to(cr, bb.x + bb.width - topRight, bb.y);
            if (topRight > 0.0)
                cairo_arc(cr, bb.x + bb.width - topRight, bb.y + topRight, topRight, 3.0 * M_PI / 2.0, 2.0 * M_PI);
            cairo_line_to(cr, bb.x + bb.width, bb.y + bb.height - bottomRight);
            if (bottomRight > 0.0)
                cairo_arc(cr, bb.x + bb.width - bottomRight, bb.y + bb.height - bottomRight, bottomRight, 0.0, M_PI / 2.0);
            else
                cairo_line_to(cr, bb.x + bb.width, bb.y + bb.height);
            break;
        case AUIRendererCairoBorderBottom:
            cairo_move_to(cr, bb.x + bb.width, bb.y + bb.height - bottomRight);
            if (bottomRight > 0.0)
                cairo_arc(cr, bb.x + bb.width - bottomRight, bb.y + bb.height - bottomRight, bottomRight, 0.0, M_PI / 2.0);
            cairo_line_to(cr, bb.x + bottomLeft, bb.y + bb.height);
            if (bottomLeft > 0.0)
                cairo_arc(cr, bb.x + bottomLeft, bb.y + bb.height - bottomLeft, bottomLeft, M_PI / 2.0, M_PI);
            else
                cairo_line_to(cr, bb.x, bb.y + bb.height);
            break;
        case AUIRendererCairoBorderLeft:
            cairo_move_to(cr, bb.x + bottomLeft, bb.y + bb.height);
            if (bottomLeft > 0.0)
                cairo_arc(cr, bb.x + bottomLeft, bb.y + bb.height - bottomLeft, bottomLeft, M_PI / 2.0, M_PI);
            cairo_line_to(cr, bb.x, bb.y + topLeft);
            if (topLeft > 0.0)
                cairo_arc(cr, bb.x + topLeft, bb.y + topLeft, topLeft, M_PI, 3.0 * M_PI / 2.0);
            else
                cairo_line_to(cr, bb.x, bb.y);
            break;
    }

    cairo_stroke(cr);
}

static void AUIRendererCairoRenderBorder(cairo_t *cr, Clay_BorderRenderData *config, Clay_BoundingBox bb)
{
    double topLeft = AUIRendererCairoClampRadius(config->cornerRadius.topLeft, bb) / 2.0;
    double topRight = AUIRendererCairoClampRadius(config->cornerRadius.topRight, bb) / 2.0;
    double bottomRight = AUIRendererCairoClampRadius(config->cornerRadius.bottomRight, bb) / 2.0;
    double bottomLeft = AUIRendererCairoClampRadius(config->cornerRadius.bottomLeft, bb) / 2.0;

    cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND);

    if (config->width.top > 0.0) {
        cairo_set_line_width(cr, config->width.top);
        AUIRendererCairoRenderBorderSide(cr, bb, config, topLeft, topRight, bottomRight, bottomLeft, AUIRendererCairoBorderTop);
    }
    if (config->width.right > 0.0) {
        cairo_set_line_width(cr, config->width.right);
        AUIRendererCairoRenderBorderSide(cr, bb, config, topLeft, topRight, bottomRight, bottomLeft, AUIRendererCairoBorderRight);
    }
    if (config->width.bottom > 0.0) {
        cairo_set_line_width(cr, config->width.bottom);
        AUIRendererCairoRenderBorderSide(cr, bb, config, topLeft, topRight, bottomRight, bottomLeft, AUIRendererCairoBorderBottom);
    }
    if (config->width.left > 0.0) {
        cairo_set_line_width(cr, config->width.left);
        AUIRendererCairoRenderBorderSide(cr, bb, config, topLeft, topRight, bottomRight, bottomLeft, AUIRendererCairoBorderLeft);
    }
}

static void AUIRendererCairoRenderText(cairo_t *cr,
                                       Clay_TextRenderData *config,
                                       Clay_BoundingBox bb,
                                       char *const *fonts)
{
    char *fontFamily = AUIRendererCairoFontFamily(fonts, config->fontId);
    char *nillable text = AUIRendererCairoCopyUTF8String(config->stringContents);

    if (text == nullptr)
        return;

    cairo_save(cr);
    cairo_identity_matrix(cr);
    cairo_select_font_face(cr, fontFamily, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size(cr, config->fontSize);

    cairo_text_extents_t textExtents;
    cairo_font_extents_t fontExtents;
    cairo_text_extents(cr, text, &textExtents);
    cairo_font_extents(cr, &fontExtents);

    double lineHeight = (config->lineHeight > 0 ? (double)config->lineHeight : fontExtents.height);
    double x = bb.x - textExtents.x_bearing;
    double y = bb.y + ((lineHeight - textExtents.height) / 2.0) - textExtents.y_bearing;

    AUIRendererCairoSetSourceColor(cr, config->textColor);

    if (config->letterSpacing == 0) {
        cairo_move_to(cr, x, y);
        cairo_show_text(cr, text);
    } else {
        cairo_scaled_font_t *scaledFont = cairo_get_scaled_font(cr);
        cairo_glyph_t *nillable glyphs = nullptr;
        int numGlyphs = 0;
        cairo_status_t status = cairo_scaled_font_text_to_glyphs(scaledFont,
                                                                 0,
                                                                 0,
                                                                 text,
                                                                 -1,
                                                                 &glyphs,
                                                                 &numGlyphs,
                                                                 nullptr,
                                                                 nullptr,
                                                                 nullptr);

        if (status == CAIRO_STATUS_SUCCESS and glyphs != nullptr and numGlyphs > 0) {
            for (int i = 0; i < numGlyphs; i++) {
                glyphs[i].x += x + (double)i * (double)config->letterSpacing;
                glyphs[i].y += y;
            }

            cairo_show_glyphs(cr, glyphs, numGlyphs);
            cairo_glyph_free(glyphs);
        } else {
            cairo_move_to(cr, x, y);
            cairo_show_text(cr, text);
        }
    }

    cairo_restore(cr);
    free(text);
}

static void AUIRendererCairoRenderImage(cairo_t *cr, Clay_ImageRenderData *config, Clay_BoundingBox bb)
{
    if (bb.width <= 0.0 or bb.height <= 0.0 or config->imageData == nullptr)
        return;

    cairo_surface_t *image = cairo_image_surface_create_from_png((const char *)config->imageData);

    if (cairo_surface_status(image) != CAIRO_STATUS_SUCCESS) {
        cairo_surface_destroy(image);
        return;
    }

    double imageWidth = (double)cairo_image_surface_get_width(image);
    double imageHeight = (double)cairo_image_surface_get_height(image);
    if (imageWidth <= 0.0 or imageHeight <= 0.0) {
        cairo_surface_destroy(image);
        return;
    }

    double scale = fmin(bb.width / imageWidth, bb.height / imageHeight);
    double scaledWidth = imageWidth * scale;
    double scaledHeight = imageHeight * scale;
    double originX = bb.x + (bb.width - scaledWidth) / 2.0;
    double originY = bb.y + (bb.height - scaledHeight) / 2.0;

    cairo_save(cr);
    AUIRendererCairoAddRoundedRect(cr, bb, config->cornerRadius);
    cairo_clip(cr);

    if (config->backgroundColor.a > 0) {
        AUIRendererCairoSetSourceColor(cr, config->backgroundColor);
        cairo_paint(cr);
    }

    cairo_translate(cr, originX, originY);
    cairo_scale(cr, scale, scale);
    cairo_set_source_surface(cr, image, 0.0, 0.0);
    cairo_paint(cr);
    cairo_restore(cr);

    cairo_surface_destroy(image);
}

static void AUIRendererCairoRenderCommand(cairo_t *cr, Clay_RenderCommand *command, char *const *fonts)
{
    switch (command->commandType) {
        case CLAY_RENDER_COMMAND_TYPE_RECTANGLE:
            AUIRendererCairoRenderRectangle(cr, &command->renderData.rectangle, command->boundingBox);
            break;
        case CLAY_RENDER_COMMAND_TYPE_TEXT:
            AUIRendererCairoRenderText(cr, &command->renderData.text, command->boundingBox, fonts);
            break;
        case CLAY_RENDER_COMMAND_TYPE_BORDER:
            AUIRendererCairoRenderBorder(cr, &command->renderData.border, command->boundingBox);
            break;
        case CLAY_RENDER_COMMAND_TYPE_SCISSOR_START: {
            Clay_BoundingBox bb = command->boundingBox;
            cairo_save(cr);
            cairo_new_path(cr);
            cairo_rectangle(cr, bb.x, bb.y, bb.width, bb.height);
            cairo_clip(cr);
            break;
        }
        case CLAY_RENDER_COMMAND_TYPE_SCISSOR_END:
            cairo_restore(cr);
            break;
        case CLAY_RENDER_COMMAND_TYPE_IMAGE:
            AUIRendererCairoRenderImage(cr, &command->renderData.image, command->boundingBox);
            break;
        case CLAY_RENDER_COMMAND_TYPE_CUSTOM:
            break;
        default:
            fprintf(stderr, "Unknown Clay command type %d\n", (int)command->commandType);
            break;
    }
}

static Clay_Dimensions AUICairoMeasureTextBridge(Clay_StringSlice text,
                                                 Clay_TextElementConfig *config,
                                                 void *userData)
{
    char *const *fonts = (char *const *)userData;
    cairo_t *cr = AUICairoRendererCurrentContext;
    char *nillable textBuffer = AUIRendererCairoCopyUTF8String(text);

    if (cr == nullptr or textBuffer == nullptr) {
        free(textBuffer);
        return (Clay_Dimensions){ 0, 0 };
    }

    cairo_save(cr);
    cairo_identity_matrix(cr);
    cairo_select_font_face(cr,
                           AUIRendererCairoFontFamily(fonts, config->fontId),
                           CAIRO_FONT_SLANT_NORMAL,
                           CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size(cr, config->fontSize);

    cairo_text_extents_t textExtents;
    cairo_font_extents_t fontExtents;
    cairo_text_extents(cr, textBuffer, &textExtents);
    cairo_font_extents(cr, &fontExtents);
    cairo_restore(cr);

    free(textBuffer);

    return (Clay_Dimensions){
        .width = (float)(textExtents.x_advance +
                         (config->letterSpacing != 0 and text.length > 1
                             ? (double)(text.length - 1) * (double)config->letterSpacing
                             : 0.0)),
        .height = (float)(config->lineHeight > 0
            ? (double)config->lineHeight
            : fmax(fontExtents.height, textExtents.height))
    };
}

@implementation AUICairoRendererBackend {
    void *nillable _clayMemory;
    size_t _clayMemorySize;
    Clay_Context *nillable _clayContext;
}

- (instancetype)initWithApplication: (AUIApplication *nillable)application
{
    self = [super initWithApplication: application];
    _clayMemory = nullptr;
    _clayMemorySize = 0;
    _clayContext = nullptr;
    return self;
}

- (void)dealloc
{
    if (_clayMemory != nullptr) {
        free(_clayMemory);
        _clayMemory = nullptr;
    }
}

- (void)_prepareForViewportSize: (AUISize)viewportSize
{
    OFString *nillable clayError = nilptr;

    if (_clayMemory == nullptr) {
        _clayMemorySize = [AUIClay minimumMemorySize];
        _clayMemory = malloc(_clayMemorySize);
        if (_clayMemory == nullptr)
            @throw [[AUIInitializationException alloc] initWithReason: @"Failed to allocate the Clay arena"];

        [AUIClay clearError];
        _clayContext = [AUIClay initializeWithMemory: $assert_nonnil(_clayMemory)
                                                size: _clayMemorySize
                                          dimensions: viewportSize];
        clayError = [AUIClay consumeError];
        if (clayError != nilptr)
            @throw [[AUIInitializationException alloc] initWithReason: $assert_nonnil(clayError)];
    }

    [AUIClay setCurrentContext: _clayContext];
    [AUIClay setLayoutDimensions: viewportSize];
}

- (void)_renderApplication: (AUIApplication *)application
                 inputState: (AUIInputState *)inputState
               viewportSize: (AUISize)viewportSize
                      cairo: (cairo_t *)cairo
{
    Clay_RenderCommandArray commands;
    OFString *nillable clayError = nilptr;

    [self _prepareForViewportSize: viewportSize];
    AUICairoRendererCurrentContext = cairo;
    Clay_SetMeasureTextFunction(AUICairoMeasureTextBridge, async_ui_cairo_fonts);
    [AUIClay setPointerPositionX: inputState.pointerX
                                y: inputState.pointerY
                             down: inputState.primaryButtonDown];
    commands = [application _buildRenderCommandsWithViewportSize: viewportSize
                                                       deltaTime: (1.0f / 60.0f)];

    clayError = [AUIClay consumeError];
    if (clayError != nilptr)
        @throw [[AUIRenderException alloc] initWithReason: $assert_nonnil(clayError)];

    for (int32_t index = 0; index < commands.length; index++)
        AUIRendererCairoRenderCommand(cairo, Clay_RenderCommandArray_Get(&commands, index), async_ui_cairo_fonts);

    clayError = [AUIClay consumeError];
    if (clayError != nilptr)
        @throw [[AUIRenderException alloc] initWithReason: $assert_nonnil(clayError)];
}

@end

#pragma clang assume_nonnull end
