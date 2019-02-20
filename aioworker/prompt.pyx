

cpdef str worker_console_template = """
                           .:
                          .lo,
                         .loo:
                 .:looc'.loo:
                ;oooooooooo:
               :oooooooooo:
              :ooooooooooo,
             .ooooooooooooo
              ,oooooooooooo.
               'ooooooooooo.
            .,  .oooooooooo.
           .lo.  .ooooooool
          .lo,    .ooooooo;
       . .lo'      .oooool
     .lo;lo.        .looc
    .loooo.       .  .lc
   .looooo,      ;o,  .
   :ooooooo,    ;oc
   ooooooooo,  ;oc         WORKER
  .oooooooooo,;oc
  .ooooooooooooc
  .oooooooooooo;    {os}-{arch}-i386-64bit {date} {time}
   loooooooooooo.   ------------------------------------
   ,ooooooooooo,
   coooooooooo,     aioworker@{hostname} {version}
  coooooooooo,
 cool..;ccc,.       [config]
cooc                .> app:         {app_id}
.oc
 ;.

[tasks]
{tasks}

[subscriptions]
{subscriptions}
"""


cpdef str agent_console_template = """

{os}-{arch}-i386-64bit {date} {time}

< Aioworker AGENT >
 -----------------
        \   ^__^                aioworker@{hostname} {version}
         \  (==)\_______
            (__)\       )\/\    [config]
                ||----w |
                ||     ||       .> app:         {app_id}

[tasks]
{tasks}

[subscriptions]
{subscriptions}
"""

cpdef dict console_templates = dict(
    agent=agent_console_template,
    worker=worker_console_template)
