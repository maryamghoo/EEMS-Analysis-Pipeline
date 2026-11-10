# EEMS plots
# Open this file in RStudio and run the lines in order with Run.

library(reemsplots2)    # EEMS surfaces and diagnostics
library(ggplot2)        # Plotting and saving figures
library(sf)             # Spatial data
library(rnaturalearth)  # Ocean boundaries
library(ggspatial)      # Scale bar and north arrow
library(ggrepel)        # Sampling location labels

# Folders in the R working directory
getwd()
r_input <- file.path(getwd(), "output")   # EEMS output copied from the cluster
r_output <- file.path(getwd(), "plots")  # Figures saved here

outer_file <- file.path(getwd(), "eems_data.outer")
coord_file <- file.path(getwd(), "eems_data.coord")
sample_file <- file.path(getwd(), "sample_coordinates.csv")

dir.create(r_output, showWarnings = FALSE, recursive = TRUE)

# Standard EEMS plots
plots <- make_eems_plots(r_input, longlat = TRUE)
names(plots)

plots$mrates01
plots$mrates02
plots$qrates01
plots$qrates02
plots$rdist01
plots$rdist02
plots$rdist03
plots$pilogl01

# Save the standard plots
ggsave(file.path(r_output, "mrates01.png"), plots$mrates01, width = 8, height = 6, dpi = 600)
ggsave(file.path(r_output, "mrates02.png"), plots$mrates02, width = 8, height = 6, dpi = 600)
ggsave(file.path(r_output, "qrates01.png"), plots$qrates01, width = 8, height = 6, dpi = 600)
ggsave(file.path(r_output, "qrates02.png"), plots$qrates02, width = 8, height = 6, dpi = 600)
ggsave(file.path(r_output, "rdist01.png"), plots$rdist01, width = 8, height = 6, dpi = 600)
ggsave(file.path(r_output, "rdist02.png"), plots$rdist02, width = 8, height = 6, dpi = 600)
ggsave(file.path(r_output, "rdist03.png"), plots$rdist03, width = 8, height = 6, dpi = 600)
ggsave(file.path(r_output, "pilogl01.png"), plots$pilogl01, width = 8, height = 6, dpi = 600)

ggsave(file.path(r_output, "mrates01.pdf"), plots$mrates01, width = 8, height = 6)
ggsave(file.path(r_output, "mrates02.pdf"), plots$mrates02, width = 8, height = 6)
ggsave(file.path(r_output, "qrates01.pdf"), plots$qrates01, width = 8, height = 6)
ggsave(file.path(r_output, "qrates02.pdf"), plots$qrates02, width = 8, height = 6)
ggsave(file.path(r_output, "rdist01.pdf"), plots$rdist01, width = 8, height = 6)
ggsave(file.path(r_output, "rdist02.pdf"), plots$rdist02, width = 8, height = 6)
ggsave(file.path(r_output, "rdist03.pdf"), plots$rdist03, width = 8, height = 6)
ggsave(file.path(r_output, "pilogl01.pdf"), plots$pilogl01, width = 8, height = 6)

# Habitat polygon
outer_coords <- read.table(outer_file, header = FALSE)
colnames(outer_coords) <- c("Longitude", "Latitude")
if (!all(outer_coords[1, ] == outer_coords[nrow(outer_coords), ])) {
  outer_coords <- rbind(outer_coords, outer_coords[1, ])
}
outer_sf <- st_sfc(st_polygon(list(as.matrix(outer_coords))), crs = 4326)

# Sample coordinates. The CSV is optional and can include Location and Region.
if (file.exists(sample_file)) {
  sample_coords <- read.csv(sample_file)
} else {
  sample_coords <- read.table(coord_file, header = FALSE)
  names(sample_coords) <- c("Longitude", "Latitude")
}
samples_sf <- st_as_sf(sample_coords, coords = c("Longitude", "Latitude"),
                       crs = 4326, remove = FALSE)

# Ocean polygons (internet required for the Natural Earth download)
ocean <- ne_download(scale = 50, type = "ocean", category = "physical",
                     returnclass = "sf")
ocean <- st_make_valid(ocean)

bounds <- st_bbox(outer_sf)
x_margin <- (bounds["xmax"] - bounds["xmin"]) * 0.05
y_margin <- (bounds["ymax"] - bounds["ymin"]) * 0.05
xlim <- c(bounds["xmin"] - x_margin, bounds["xmax"] + x_margin)
ylim <- c(bounds["ymin"] - y_margin, bounds["ymax"] + y_margin)

crop_bounds <- bounds
crop_bounds[c("xmin", "xmax")] <- xlim
crop_bounds[c("ymin", "ymax")] <- ylim
ocean <- st_crop(ocean, crop_bounds)

# Optional colors and location labels
point_layer <- geom_sf(data = samples_sf, color = "black", size = 2,
                       inherit.aes = FALSE)
if ("Region" %in% names(sample_coords)) {
  point_layer <- geom_sf(data = samples_sf, aes(color = Region), size = 2,
                         inherit.aes = FALSE)
}

label_layer <- NULL
if ("Location" %in% names(sample_coords)) {
  sample_labels <- sample_coords[!duplicated(sample_coords$Location), ]
  label_layer <- geom_text_repel(data = sample_labels,
                                 aes(x = Longitude, y = Latitude, label = Location),
                                 inherit.aes = FALSE, size = 3, seed = 42,
                                 max.overlaps = 100)
}

# Add the same geographic layers to each EEMS map
map_layers <- list(
  geom_sf(data = ocean, fill = "lightblue", color = NA, inherit.aes = FALSE),
  geom_sf(data = outer_sf, fill = NA, color = "black", linewidth = 0.6,
          inherit.aes = FALSE),
  point_layer,
  label_layer,
  coord_sf(xlim = xlim, ylim = ylim, expand = FALSE),
  annotation_scale(location = "br", width_hint = 0.3),
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_fancy_orienteering),
  theme_void()
)

# Migration and diversity maps
# Keep the reemsplots2 scales: *02 plots show posterior probabilities.
mrates01_map <- plots$mrates01 + map_layers
mrates02_map <- plots$mrates02 + map_layers
qrates01_map <- plots$qrates01 + map_layers
qrates02_map <- plots$qrates02 + map_layers

mrates01_map
mrates02_map
qrates01_map
qrates02_map

# Save geographic maps
ggsave(file.path(r_output, "mrates01_map.png"), mrates01_map, width = 10, height = 8, dpi = 600)
ggsave(file.path(r_output, "mrates02_map.png"), mrates02_map, width = 10, height = 8, dpi = 600)
ggsave(file.path(r_output, "qrates01_map.png"), qrates01_map, width = 10, height = 8, dpi = 600)
ggsave(file.path(r_output, "qrates02_map.png"), qrates02_map, width = 10, height = 8, dpi = 600)

ggsave(file.path(r_output, "mrates01_map.pdf"), mrates01_map, width = 10, height = 8)
ggsave(file.path(r_output, "mrates02_map.pdf"), mrates02_map, width = 10, height = 8)
ggsave(file.path(r_output, "qrates01_map.pdf"), qrates01_map, width = 10, height = 8)
ggsave(file.path(r_output, "qrates02_map.pdf"), qrates02_map, width = 10, height = 8)

ggsave(file.path(r_output, "mrates01_map.svg"), mrates01_map, width = 10, height = 8)
ggsave(file.path(r_output, "mrates02_map.svg"), mrates02_map, width = 10, height = 8)
ggsave(file.path(r_output, "qrates01_map.svg"), qrates01_map, width = 10, height = 8)
ggsave(file.path(r_output, "qrates02_map.svg"), qrates02_map, width = 10, height = 8)
