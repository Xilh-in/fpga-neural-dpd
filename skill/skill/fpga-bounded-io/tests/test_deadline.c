#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include "../assets/deadline_io.h"
typedef struct { uint64_t ticks; size_t position, length; uint8_t bytes[4]; uint32_t status; } fixture;
static uint64_t now(void *p) { fixture *f=p; return f->ticks++; }
static int ready(void *p) { fixture *f=p; return f->position < f->length; }
static uint8_t byte(void *p) { fixture *f=p; return f->bytes[f->position++]; }
static uint32_t status(void *p) { fixture *f=p; return f->status; }
#define CHECK(x) do { if (!(x)) { puts("FAIL: " #x); return 1; } } while (0)
int main(void)
{
    uint8_t staging[4]={0};
    fixture f={0,0,4,{1,2,3,4},1};
    CHECK(skill_receive_staged(&f,now,ready,byte,staging,4,4,20,5));
    CHECK(staging[0]==1 && staging[3]==4);
    f.ticks=0;f.position=0;f.length=3;
    CHECK(!skill_receive_staged(&f,now,ready,byte,staging,4,4,20,5));
    f.ticks=0;f.status=0;
    CHECK(!skill_poll_status(&f,now,status,1,4));
    f.ticks=0;f.status=1;
    CHECK(!skill_poll_status(&f,now,status,0,4));
    f.ticks=0;
    CHECK(skill_poll_status(&f,now,status,1,4));
    CHECK(!skill_receive_staged(&f,now,ready,byte,staging,5,4,20,5));
    puts("PORTABLE_C_CALLBACK_TESTS_PASS");
    return 0;
}
