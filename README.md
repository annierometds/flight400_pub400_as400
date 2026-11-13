# Build Flight400 on PUB400

This folder (`pub400-build`) holds the Flight400 source code taken out of `FLGHT400.FILE` and adjusted to run in your own PUB400 library. You don't need the save file or the TechZone 7.6 system for this build. `CHANGES.md` lists every edit.

```
pub400-build/
  build.sh            run this on PUB400
  src/QRPGSRC/        original RPG programs (these get compiled)
  src/QRPGLESRC/      Bob-modernized versions (source only, for demos)
  src/QDDSSRCF/       physical and logical files
  src/QDDSSRCD/       display files
  src/QCLPSRC/        CL programs, including FLBUILD (the build program)
  src/QCMDSRC/        commands
  src/QMNUSRC/        menus FRSMAIN / FRSMANT / FRSREPT
  src/QSQLSRC/SEED    seed data
```

## 1. Find your library name

PUB400 gives you libraries named after your user profile. On your Mac, run:

```
ssh -p 2222 USERNAME@pub400.com 'ls -d /QSYS.LIB/USERNAME*.LIB'
```

Pick one of the libraries it lists, for example `USERNAME1`. Every step below uses `USERNAME1`. Replace it with your library if yours has a different name.

## 2. Upload the build folder

Upload only `pub400-build`. Leave out `FLGHT400.FILE` (275 MB) and `ssh_private_key.pem`:

```
cd ~/Desktop/flight400_pub400
scp -P 2222 -r pub400-build USERNAME@pub400.com:flight400
```

This creates `/home/USERNAME/flight400` on PUB400.

## 3. Run the build

```
ssh -p 2222 USERNAME@pub400.com
cd flight400
sh build.sh USERNAME1
```

The build runs in three steps:

1. It creates the source files in your library (CCSID 37) and copies every member in.
2. It compiles `FLBUILD`.
3. It runs `FLBUILD` twice:
   - **COMPILE** creates, in order: the message file `FRSMSGF`, then 10 physical files, 14 logical files, 28 display files, 30 RPG programs, 10 CL programs, 2 commands and 3 menus.
   - **DATA** loads the seed data. It then runs the app's own generators: `BFLGHT` fills FLIGHTS and `BLDCST`/`BCUST` fills CUSTOMERS. This step takes the longest.

When the build finishes, the script prints any lines marked `FAILED` and a summary line such as `SUMMARY COMPILE ok=... failed=...`. The full logs are saved as `build-compile.log` and `build-data.log` next to `build.sh`.

To re-run only part of the build:

```
sh build.sh USERNAME1 compile     # recompile only. Existing files and data are left alone.
sh build.sh USERNAME1 data        # clear and reload the data only
```

## 4. Run the app

Sign on to PUB400 with a 5250 session, either ACS 5250 to `pub400.com` or any tn5250 client. Then run:

```
ADDLIBLE ANNIEROME1
GO FRSMAIN
```

The logon screen accepts agent **Julia** with password **mercury** (all agents use `mercury`). Press F4 on the agent field to pick from the list. The FLIGHT400-GUIDE.md walkthrough works as written, with two differences:

- Customers are generated at random by `BCUST`. The sample customers in the guide such as "Brandle, Jimmy" won't be in the list, so press **F7** and pick any customer.
- Flight numbers and times are also regenerated, so use **F6** to choose a flight.

