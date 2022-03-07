// Light Panel
//
// @author Natesh Narain <nnaraindev@gmail.com>
//

include <NopSCADlib/core.scad>
include <BOSL/constants.scad>
use <BOSL/shapes.scad>
use <BOSL/transforms.scad>

// Number of sides for the panel
number_of_sides = 3;

// Length from the center to the outer vertex
frame_radius = 70;
// Width of the visbile rim around the panel
frame_rim = 3;
// Width of the ledge the panel sits on
frame_ledge = 3;
// Height of the ledge (where the panel rests) as the percentage of the frame height
ledge_height_factor = 0.5;
// Thickness of the frame
frame_thickness = 2;
// Height of the frame
frame_height = 20;

// Thickness of the panel
panel_thickness = 0.4;
// Thickness of the sides of the panel
panel_side_thickness = 4;
// Clearance between the panel and the edge of the frame
panel_clearance = 1.75;
// The amount the panel will protrude from the frame
panel_height_visible = 5;

// Interior frame size ratio (where the LEDs go)
interior_frame_ratio = 0.5; // [0.0:0.01:1.0]
// Interior frame width
interior_frame_width = 10;
// Interior frame strut width
strut_width = 10;
// Connector cutout width
connector_cutout_width = 20;
// Connector cutout height
connector_cutout_height = 3;
// Connector z-offset
connector_z_offset = 4;
// Distance between the connector and the screw holes
connector_screw_hole_distance = 5;
// Radius of the connecting screw holes
screw_hole_radius = 2;
// Height of the screw holes
screw_hole_height = 1;


/* [Hidden] */
// Used to union/diff objects
delta = 0.001;

/* Dervied Properties */
panel_radius = frame_radius - frame_thickness - panel_clearance;
panel_height = frame_height * (1.0 - ledge_height_factor) + panel_height_visible;

polygon_angle = (number_of_sides - 2) * (180 / number_of_sides);
vertex_to_side_angle = number_of_sides % 2 == 0 ? polygon_angle / 2 : polygon_angle;
vertex_to_vertex_angle = 180 - ((polygon_angle / 2) * 2);

// cosine rule
side_length = sqrt((frame_radius^2) + (frame_radius^2) - 2 * frame_radius * frame_radius * cos(vertex_to_vertex_angle));

// Give the basic shape the panel is supposed to be
module base_shape(radius, height) {
    cylinder(r=radius, h=height, $fn=number_of_sides);
}

// Create the frame to which the panel will on top of
module frame() {
    outer_frame_interior_radius = frame_radius - frame_rim;

    union() {
        // Outer frame
        difference() {
            union() {
                base_shape_with_cutout(frame_radius, outer_frame_interior_radius, frame_height);

                ledge_radius = outer_frame_interior_radius - frame_ledge;
                ledge_height = frame_height * ledge_height_factor;
                base_shape_with_cutout(outer_frame_interior_radius + delta, ledge_radius, ledge_height);
            }

            for (i = [0:number_of_sides]) {
                zrot((vertex_to_vertex_angle * i) + vertex_to_vertex_angle / 2)
                    zmove(connector_z_offset)
                        screw_cable_cutout(frame_radius + delta);
            }
        }

        // screw_cable_cutout(frame_radius);

        // Inner support frame
        support_frame_radius = outer_frame_interior_radius + delta;

        // The interior frame for support and where the LEDs will go
        interior_frame_radius = support_frame_radius * interior_frame_ratio;

        difference() {
            // Create struts to each vertex for support
            union() {
                for (i = [0:number_of_sides]) {
                    zrot(vertex_to_vertex_angle * i) {
                        strut(support_frame_radius, strut_width, frame_thickness);
                    }
                }
            }

            zmove(-delta) base_shape(interior_frame_radius, frame_thickness + 2 * delta);
        }

        interior_frame_inner_radius = interior_frame_radius - interior_frame_width;
        base_shape_with_cutout(interior_frame_radius, interior_frame_inner_radius, frame_thickness);
    }
}

module strut(radius, width, height) {
    intersection() {
        base_shape(radius, height);
        translate([0, -width / 2, 0]) {
            cube(size=[radius, strut_width, height], center=false);
        }
    }
}

module screw_cable_cutout(r) {
    union() {
        translate([0, -connector_cutout_width / 2, 0]) {
            cube(size=[r, connector_cutout_width, connector_cutout_height], center=false);
        }

        screw_hole_offset = (connector_cutout_width / 2) + connector_screw_hole_distance;
        translate([r / 2, screw_hole_offset, screw_hole_height])
            yrot(90)
                cylinder(r=screw_hole_radius, h=r, center=true);
        translate([r / 2, -screw_hole_offset, screw_hole_height])
            yrot(90)
                cylinder(r=screw_hole_radius, h=r, center=true);
    }
}

module base_shape_with_cutout(outer_radius, inner_radius, height) {
    difference() {
        base_shape(outer_radius, height);
        zmove(-delta)
            base_shape(inner_radius, height + 2 * delta);
    }
}

// Create the panel
module panel() {
    union() {
        // Visible portion of the panel that the LED will illuminate
        base_shape(panel_radius, panel_thickness);
        // The edges of the panel so it can be slot into the frame
        zmove(-delta)
            base_shape_with_cutout(panel_radius, panel_radius - panel_side_thickness, panel_height);
    }
}

module frame_stl() {
    stl("frame");
    frame();
}

module panel_stl() {
    stl("panel");
    panel();
}

module main_assembly() {
assembly("main") {
    translate([0, 0, 30])
        xrot(180) color("white") panel_stl();
    color("grey") frame_stl();
}
}

if ($preview) {
    main_assembly();
}
