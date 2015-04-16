#include <stdint.h>

#define BUFSIZE 8192

#define CMD_KEY 0
#define CMD_MOUSE 1

extern uint16_t pre, post;
extern uint16_t position[];
extern int8_t lastn;
extern uint8_t buffer[];

inline void movebuf(int32_t offset);

void handle_packet(uint16_t packet)
{
    uint8_t cmd_n = (packet & 0x3000) >> 12;
    uint8_t cmd_type = (packet & 0x0f80) >> 7;
    uint8_t cmd_data = packet & 0x007f;

    /* move buffer to center around cursor of the command's n */
    if (cmd_n != lastn) {
        if (lastn != -1) {
            movebuf(position[cmd_n] - position[lastn]);
        }
        lastn = cmd_n;
    }

    int32_t temp, temp2, i, column;
    switch (cmd_type) {
    case CMD_KEY:
        if (cmd_data > 6) {     /* actual ascii codes */
            buffer[pre++] = cmd_data;

            /* move all other positions */
            for (i = 0; i < 4; ++i) {
                if (i == cmd_n)
                    continue;
                if (position[i] >= position[cmd_n])
                    ++position[i];
            }
            ++position[cmd_n];
        } else {
            switch (cmd_data) {
            case 0:             /* left */
                if (pre != 0) {
                    buffer[--post] = buffer[--pre];
                    --position[cmd_n];
                }

                break;
            case 1:             /* right */
                if (post != BUFSIZE - 1) {
                    buffer[pre++] = buffer[post++];
                    ++position[cmd_n];
                }
                break;
            case 2:
            case 3:       /* up and down */
                /* common: check what column cursor is at */
                if (cmd_data == 2 && pre == 0) {
                    break;
                }
                temp = pre - 1;
                column = 0;
                while (temp >= 0 && buffer[temp] != 10) {
                    --temp;
                    ++column;
                }

                if (cmd_data == 2) { /* up */
                    if (temp == -1) {
                        position[cmd_n] -= pre;
                        movebuf(-1 * pre);
                    } else {
                        /* special case of up'ing into an empty line */
                        if (buffer[temp] == 10 && buffer[temp-1] == 10) {
                            position[cmd_n] += temp - pre;
                            movebuf(temp - pre);
                        } else {
                            if (buffer[temp] != 10) { /* more hax */
                                --temp;
                            } else {
                                temp -= 2;
                            }
                            while (temp >= 0 && buffer[temp] != 10) {
                                --temp;
                            }
                            temp2 = 1;
                            while (temp2 < column && buffer[temp+temp2+1] != 10) {
                                ++temp2;
                            }
                            if (column == 0) { /* hax */
                                --temp2;
                            }
                            position[cmd_n] += temp + temp2 - pre + 1;
                            movebuf(temp + temp2 - pre + 1);
                        }
                    }
                } else {        /* down */
                    temp = post;
                    while (buffer[temp] != 0 && buffer[temp] != 10) {
                        ++temp;
                    }
                    if (buffer[temp] == 0) {
                        position[cmd_n] += temp - post;
                        movebuf(temp - post);
                    } else {
                        printf("%d %d\n", temp, buffer[temp]);
                        if (buffer[temp+1] == 10) {
                            position[cmd_n] += temp - post + 1;
                            movebuf(temp - post + 1);
                        } else {
                            temp2 = 1;
                            while (temp2 < column && buffer[temp+temp2+1] != 0 && buffer[temp+temp2+1] != 10) {
                                ++temp2;
                            };
                            if (column != 0 && buffer[temp+temp2] != 10 && buffer[temp+temp2] != 0) { /* hax */
                                ++temp2;
                            }
                            position[cmd_n] += temp + temp2 - post;
                            movebuf(temp + temp2 - post);
                        }
                    }
                }

                break;
            case 4:             /* backspace */
                if (pre != 0) {
                    --pre;
                    for (i = 0; i < 4; ++i) {
                        if (i == cmd_n)
                            continue;
                        if (position[i] >= position[cmd_n])
                            --position[i];
                    }
                    --position[cmd_n];
                }

                break;
            case 5:                      /* delete */
                if (post != BUFSIZE - 1) {
                    ++post;
                    for (i = 0; i < 4; ++i) {
                        if (position[i] > position[cmd_n])
                            --position[i];
                    }
                }

                break;
            case 6:  break;     /* no-op */
            }
        }
        
        break;
    case CMD_MOUSE:
        /* lol */
        break;
    }
}

void movebuf(int32_t offset)
{
    if (offset > 0) {
        while (offset--) {
            buffer[pre++] = buffer[post++];
        }
    } else {
        while (offset++) {
            buffer[--post] = buffer[--pre];
        }
    }
}
