#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#import <AsyncRT/Application/UI/Surface/Immediate/Platform/Cairo/RenderSupport.h>

#pragma clang assume_nonnull begin

typedef enum AsyncUICairoBorderSide {
    AsyncUICairoBorderSideTop,
    AsyncUICairoBorderSideRight,
    AsyncUICairoBorderSideBottom,
    AsyncUICairoBorderSideLeft
} AsyncUICairoBorderSide;

[[direct_members]]
@interface AsyncUICairoRenderSupport ()

+ (double)channelForValue: (uint8_t)value;
+ (void)applySourceColor: (Clay_Color)color onContext: (cairo_t *)context;
+ (double)clampedRadius: (double)radius forBoundingBox: (Clay_BoundingBox)boundingBox;
+ (char *nillable)copyUTF8String: (Clay_StringSlice)text;
+ (char *)fontFamilyInFonts: (char *const *nillable)fonts fontID: (uint16_t)fontID;
+ (void)addRoundedRectToContext: (cairo_t *)context
                    boundingBox: (Clay_BoundingBox)boundingBox
                         radius: (Clay_CornerRadius)radius;
+ (void)renderRectangleWithContext: (cairo_t *)context
                            config: (Clay_RectangleRenderData *)config
                       boundingBox: (Clay_BoundingBox)boundingBox;
+ (void)renderBorderSideWithContext: (cairo_t *)context
                            boundingBox: (Clay_BoundingBox)boundingBox
                                 config: (Clay_BorderRenderData *)config
                                topLeft: (double)topLeft
                               topRight: (double)topRight
                            bottomRight: (double)bottomRight
                             bottomLeft: (double)bottomLeft
                                   side: (AsyncUICairoBorderSide)side;
+ (void)renderBorderWithContext: (cairo_t *)context
                         config: (Clay_BorderRenderData *)config
                    boundingBox: (Clay_BoundingBox)boundingBox;
+ (void)renderTextWithContext: (cairo_t *)context
                       config: (Clay_TextRenderData *)config
                  boundingBox: (Clay_BoundingBox)boundingBox
                        fonts: (char *const *nillable)fonts;
+ (void)renderImageWithContext: (cairo_t *)context
                        config: (Clay_ImageRenderData *)config
                   boundingBox: (Clay_BoundingBox)boundingBox;
+ (void)renderCommandWithContext: (cairo_t *)context
                            command: (Clay_RenderCommand *)command
                              fonts: (char *const *nillable)fonts;

@end

@namespace_implementation(AsyncUICairoRenderSupport)

+ (double)channelForValue: (uint8_t)value
{
    return ((double)value) / 255.0;
}

+ (void)applySourceColor: (Clay_Color)color onContext: (cairo_t *)context
{
    cairo_set_source_rgba(context,
                          [self channelForValue: color.r],
                          [self channelForValue: color.g],
                          [self channelForValue: color.b],
                          [self channelForValue: color.a]);
}

+ (double)clampedRadius: (double)radius forBoundingBox: (Clay_BoundingBox)boundingBox
{
    double maxRadius = fmax(0.0, fmin(boundingBox.width, boundingBox.height) / 2.0);

    if (radius < 0.0)
        return 0.0;
    if (radius > maxRadius)
        return maxRadius;
    return radius;
}

+ (char *nillable)copyUTF8String: (Clay_StringSlice)text
{
    char *copy = malloc((size_t)text.length + 1);

    if (copy == nullptr)
        return nullptr;

    memcpy(copy, text.chars, (size_t)text.length);
    copy[text.length] = '\0';
    return copy;
}

+ (char *)fontFamilyInFonts: (char *const *nillable)fonts fontID: (uint16_t)fontID
{
    if (fonts == nullptr)
        return (char *)"Sans";

    return (fonts[fontID] != nullptr ? fonts[fontID] : (char *)"Sans");
}

+ (void)addRoundedRectToContext: (cairo_t *)context
                    boundingBox: (Clay_BoundingBox)boundingBox
                         radius: (Clay_CornerRadius)radius
{
    double topLeft = [self clampedRadius: radius.topLeft forBoundingBox: boundingBox];
    double topRight = [self clampedRadius: radius.topRight forBoundingBox: boundingBox];
    double bottomRight = [self clampedRadius: radius.bottomRight forBoundingBox: boundingBox];
    double bottomLeft = [self clampedRadius: radius.bottomLeft forBoundingBox: boundingBox];

    cairo_new_sub_path(context);
    cairo_move_to(context, boundingBox.x + topLeft, boundingBox.y);
    cairo_line_to(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y);

    if (topRight > 0.0)
        cairo_arc(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y + topRight, topRight, 3.0 * M_PI / 2.0, 2.0 * M_PI);
    else
        cairo_line_to(context, boundingBox.x + boundingBox.width, boundingBox.y);

    cairo_line_to(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height - bottomRight);

    if (bottomRight > 0.0)
        cairo_arc(context, boundingBox.x + boundingBox.width - bottomRight, boundingBox.y + boundingBox.height - bottomRight, bottomRight, 0.0, M_PI / 2.0);
    else
        cairo_line_to(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height);

    cairo_line_to(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height);

    if (bottomLeft > 0.0)
        cairo_arc(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height - bottomLeft, bottomLeft, M_PI / 2.0, M_PI);
    else
        cairo_line_to(context, boundingBox.x, boundingBox.y + boundingBox.height);

    cairo_line_to(context, boundingBox.x, boundingBox.y + topLeft);

    if (topLeft > 0.0)
        cairo_arc(context, boundingBox.x + topLeft, boundingBox.y + topLeft, topLeft, M_PI, 3.0 * M_PI / 2.0);
    else
        cairo_line_to(context, boundingBox.x, boundingBox.y);

    cairo_close_path(context);
}

+ (void)renderRectangleWithContext: (cairo_t *)context
                            config: (Clay_RectangleRenderData *)config
                       boundingBox: (Clay_BoundingBox)boundingBox
{
    [self applySourceColor: config->backgroundColor onContext: context];
    [self addRoundedRectToContext: context boundingBox: boundingBox radius: config->cornerRadius];
    cairo_fill(context);
}

+ (void)renderBorderSideWithContext: (cairo_t *)context
                        boundingBox: (Clay_BoundingBox)boundingBox
                             config: (Clay_BorderRenderData *)config
                            topLeft: (double)topLeft
                           topRight: (double)topRight
                        bottomRight: (double)bottomRight
                         bottomLeft: (double)bottomLeft
                               side: (AsyncUICairoBorderSide)side
{
    [self applySourceColor: config->color onContext: context];
    cairo_new_sub_path(context);

    switch (side) {
        case AsyncUICairoBorderSideTop:
            cairo_move_to(context, boundingBox.x, boundingBox.y + topLeft);
            if (topLeft > 0.0)
                cairo_arc(context, boundingBox.x + topLeft, boundingBox.y + topLeft, topLeft, M_PI, 3.0 * M_PI / 2.0);
            else
                cairo_line_to(context, boundingBox.x, boundingBox.y);
            cairo_line_to(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y);
            if (topRight > 0.0)
                cairo_arc(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y + topRight, topRight, 3.0 * M_PI / 2.0, 2.0 * M_PI);
            else
                cairo_line_to(context, boundingBox.x + boundingBox.width, boundingBox.y);
            break;
        case AsyncUICairoBorderSideRight:
            cairo_move_to(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y);
            if (topRight > 0.0)
                cairo_arc(context, boundingBox.x + boundingBox.width - topRight, boundingBox.y + topRight, topRight, 3.0 * M_PI / 2.0, 2.0 * M_PI);
            cairo_line_to(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height - bottomRight);
            if (bottomRight > 0.0)
                cairo_arc(context, boundingBox.x + boundingBox.width - bottomRight, boundingBox.y + boundingBox.height - bottomRight, bottomRight, 0.0, M_PI / 2.0);
            else
                cairo_line_to(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height);
            break;
        case AsyncUICairoBorderSideBottom:
            cairo_move_to(context, boundingBox.x + boundingBox.width, boundingBox.y + boundingBox.height - bottomRight);
            if (bottomRight > 0.0)
                cairo_arc(context, boundingBox.x + boundingBox.width - bottomRight, boundingBox.y + boundingBox.height - bottomRight, bottomRight, 0.0, M_PI / 2.0);
            cairo_line_to(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height);
            if (bottomLeft > 0.0)
                cairo_arc(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height - bottomLeft, bottomLeft, M_PI / 2.0, M_PI);
            else
                cairo_line_to(context, boundingBox.x, boundingBox.y + boundingBox.height);
            break;
        case AsyncUICairoBorderSideLeft:
            cairo_move_to(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height);
            if (bottomLeft > 0.0)
                cairo_arc(context, boundingBox.x + bottomLeft, boundingBox.y + boundingBox.height - bottomLeft, bottomLeft, M_PI / 2.0, M_PI);
            cairo_line_to(context, boundingBox.x, boundingBox.y + topLeft);
            if (topLeft > 0.0)
                cairo_arc(context, boundingBox.x + topLeft, boundingBox.y + topLeft, topLeft, M_PI, 3.0 * M_PI / 2.0);
            else
                cairo_line_to(context, boundingBox.x, boundingBox.y);
            break;
    }

    cairo_stroke(context);
}

+ (void)renderBorderWithContext: (cairo_t *)context
                         config: (Clay_BorderRenderData *)config
                    boundingBox: (Clay_BoundingBox)boundingBox
{
    double topLeft = [self clampedRadius: config->cornerRadius.topLeft forBoundingBox: boundingBox] / 2.0;
    double topRight = [self clampedRadius: config->cornerRadius.topRight forBoundingBox: boundingBox] / 2.0;
    double bottomRight = [self clampedRadius: config->cornerRadius.bottomRight forBoundingBox: boundingBox] / 2.0;
    double bottomLeft = [self clampedRadius: config->cornerRadius.bottomLeft forBoundingBox: boundingBox] / 2.0;

    cairo_set_line_join(context, CAIRO_LINE_JOIN_ROUND);

    if (config->width.top > 0.0) {
        cairo_set_line_width(context, config->width.top);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AsyncUICairoBorderSideTop];
    }
    if (config->width.right > 0.0) {
        cairo_set_line_width(context, config->width.right);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AsyncUICairoBorderSideRight];
    }
    if (config->width.bottom > 0.0) {
        cairo_set_line_width(context, config->width.bottom);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AsyncUICairoBorderSideBottom];
    }
    if (config->width.left > 0.0) {
        cairo_set_line_width(context, config->width.left);
        [self renderBorderSideWithContext: context boundingBox: boundingBox config: config topLeft: topLeft topRight: topRight bottomRight: bottomRight bottomLeft: bottomLeft side: AsyncUICairoBorderSideLeft];
    }
}

+ (void)renderTextWithContext: (cairo_t *)context
                       config: (Clay_TextRenderData *)config
                  boundingBox: (Clay_BoundingBox)boundingBox
                        fonts: (char *const *nillable)fonts
{
    char *fontFamily = [self fontFamilyInFonts: fonts fontID: config->fontId];
    char *nillable text = [self copyUTF8String: config->stringContents];

    if (text == nullptr)
        return;

    cairo_save(context);
    cairo_select_font_face(context, fontFamily, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size(context, config->fontSize);

    cairo_text_extents_t textExtents;
    cairo_font_extents_t fontExtents;
    cairo_text_extents(context, text, &textExtents);
    cairo_font_extents(context, &fontExtents);

    double lineHeight = (config->lineHeight > 0 ? (double)config->lineHeight : fontExtents.height);
    double x = boundingBox.x - textExtents.x_bearing;
    double y = boundingBox.y + ((lineHeight - textExtents.height) / 2.0) - textExtents.y_bearing;

    [self applySourceColor: config->textColor onContext: context];

    if (config->letterSpacing == 0) {
        cairo_move_to(context, x, y);
        cairo_show_text(context, text);
    } else {
        cairo_scaled_font_t *scaledFont = cairo_get_scaled_font(context);
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

            cairo_show_glyphs(context, glyphs, numGlyphs);
            cairo_glyph_free(glyphs);
        } else {
            cairo_move_to(context, x, y);
            cairo_show_text(context, text);
        }
    }

    cairo_restore(context);
    free(text);
}

+ (void)renderImageWithContext: (cairo_t *)context
                        config: (Clay_ImageRenderData *)config
                   boundingBox: (Clay_BoundingBox)boundingBox
{
    if (boundingBox.width <= 0.0 or boundingBox.height <= 0.0 or config->imageData == nullptr)
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

    double scale = fmin(boundingBox.width / imageWidth, boundingBox.height / imageHeight);
    double scaledWidth = imageWidth * scale;
    double scaledHeight = imageHeight * scale;
    double originX = boundingBox.x + (boundingBox.width - scaledWidth) / 2.0;
    double originY = boundingBox.y + (boundingBox.height - scaledHeight) / 2.0;

    cairo_save(context);
    [self addRoundedRectToContext: context boundingBox: boundingBox radius: config->cornerRadius];
    cairo_clip(context);

    if (config->backgroundColor.a > 0) {
        [self applySourceColor: config->backgroundColor onContext: context];
        cairo_paint(context);
    }

    cairo_translate(context, originX, originY);
    cairo_scale(context, scale, scale);
    cairo_set_source_surface(context, image, 0.0, 0.0);
    cairo_paint(context);
    cairo_restore(context);

    cairo_surface_destroy(image);
}

+ (void)renderCommandWithContext: (cairo_t *)context
                         command: (Clay_RenderCommand *)command
                           fonts: (char *const *nillable)fonts
{
    switch (command->commandType) {
        case CLAY_RENDER_COMMAND_TYPE_RECTANGLE:
            [self renderRectangleWithContext: context config: &command->renderData.rectangle boundingBox: command->boundingBox];
            break;
        case CLAY_RENDER_COMMAND_TYPE_TEXT:
            [self renderTextWithContext: context config: &command->renderData.text boundingBox: command->boundingBox fonts: fonts];
            break;
        case CLAY_RENDER_COMMAND_TYPE_BORDER:
            [self renderBorderWithContext: context config: &command->renderData.border boundingBox: command->boundingBox];
            break;
        case CLAY_RENDER_COMMAND_TYPE_SCISSOR_START: {
            Clay_BoundingBox boundingBox = command->boundingBox;

            cairo_save(context);
            cairo_new_path(context);
            cairo_rectangle(context, boundingBox.x, boundingBox.y, boundingBox.width, boundingBox.height);
            cairo_clip(context);
            break;
        }
        case CLAY_RENDER_COMMAND_TYPE_SCISSOR_END:
            cairo_restore(context);
            break;
        case CLAY_RENDER_COMMAND_TYPE_IMAGE:
            [self renderImageWithContext: context config: &command->renderData.image boundingBox: command->boundingBox];
            break;
        case CLAY_RENDER_COMMAND_TYPE_CUSTOM:
            break;
        default:
            fprintf(stderr, "Unknown Clay command type %d\n", (int)command->commandType);
            break;
    }
}

+ (void)renderCommands: (Clay_RenderCommandArray)commands
              onContext: (cairo_t *)context
                  fonts: (char *const *)fonts
{
    for (int32_t index = 0; index < commands.length; index++)
        [self renderCommandWithContext: context
                               command: Clay_RenderCommandArray_Get(&commands, index)
                                 fonts: fonts];
}

@end

Clay_Dimensions AsyncUICairoMeasureText(Clay_StringSlice text,
                                    Clay_TextElementConfig *config,
                                    void *nillable userData)
{
    AsyncUICairoTextMeasureContext *measureContext = userData;
    cairo_t *nillable context = (measureContext != nullptr
        ? measureContext->context
        : (cairo_t *nillable)nullptr);
    char *const *fonts = (measureContext != nullptr ? measureContext->fonts : nullptr);
    char *nillable textBuffer = [AsyncUICairoRenderSupport copyUTF8String: text];

    if (context == nullptr or textBuffer == nullptr) {
        free(textBuffer);
        return (Clay_Dimensions){ 0, 0 };
    }

    cairo_save($assert_nonnil(context));
    cairo_identity_matrix($assert_nonnil(context));
    cairo_select_font_face($assert_nonnil(context),
                           [AsyncUICairoRenderSupport fontFamilyInFonts: fonts fontID: config->fontId],
                           CAIRO_FONT_SLANT_NORMAL,
                           CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size($assert_nonnil(context), config->fontSize);

    cairo_text_extents_t textExtents;
    cairo_font_extents_t fontExtents;

    cairo_text_extents($assert_nonnil(context), textBuffer, &textExtents);
    cairo_font_extents($assert_nonnil(context), &fontExtents);
    cairo_restore($assert_nonnil(context));
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

#pragma clang assume_nonnull end
