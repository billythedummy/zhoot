/* Common definitions for use in enemy subsystem
*/
package enemy_def;

    typedef enum {
        S_DEAD,
        S_ALIVE,
        S_DYING
    } enemy_state_t;

    localparam ENEMY_D = 64; // width/height of enemy
    localparam HALF_ENEMY_D = ENEMY_D >> 1;
    localparam LOG_ENEMY_D = $clog2(ENEMY_D);
endpackage : enemy_def