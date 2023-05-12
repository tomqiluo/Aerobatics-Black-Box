#include <stdio.h>
#include <stdlib.h>

int main() {
    FILE *input_file = fopen("GPS_IMU_combined.csv", "r");
    FILE *output_file = fopen("output.fdr", "w");
    int count = 0;
    int number = 0;

    if (input_file == NULL) {
        printf("Error opening input file.\n");
        return 1;
    }

    if (output_file == NULL) {
        printf("Error opening output file.\n");
        fclose(input_file);
        return 1;
    }

    fprintf(output_file, "A\n3\nThis is the needed beginning of the file: 'A' or 'I' for 'Apple' or 'IBM' carriage-returns, followed by an IMMEDIATE carriage return, followed by the version number of 3\n\n");
    fprintf(output_file, "COMM, This is a sample FDR file, use it to generate your own Flight Data Recorder files!\n\n");
    fprintf(output_file, "COMM, for the ACFT label, enter the aicraft path in X-Plane\n");
    fprintf(output_file, "COMM, for the TAIL label, enter the tail number\n");
    fprintf(output_file, "COMM, for the TIME label, enter the local time in xx:xx:xx format\n");
    fprintf(output_file, "COMM, for the DATE label, enter the local time in xx/xx/xx format\n");
    fprintf(output_file, "COMM, for the PRES label, enter the local baro pressure in inches\n");
    fprintf(output_file, "COMM, for the DISA label, enter the temperature offset from ISA in degrees C\n");
    fprintf(output_file, "COMM, for the WIND label, enter the wind direction and speed in knots\n\n");
    fprintf(output_file, "COMM, Now, below that, see the DREF lines?\n");
    fprintf(output_file, "COMM, Each of those is a dataref in X-Plane, followed by a unit conversion to go from your desired input to the X-Plane units, which are typically english for indications, and metric for internal data.\n");
    fprintf(output_file, "COMM, See the total list at https://developer.x-plane.com/datarefs/\n");
    fprintf(output_file, "COMM, These are the datarefs you will drive each frame in the sim... Enter as few or as many as you like!\n\n");
    fprintf(output_file, "COMM, Now, see the DATA lines below?\n");
    fprintf(output_file, "COMM, Each of those is a TIME IN SECONDS FROM FILE-START, LONGITUDE, LATITUDE, ELEVATION IN FEET, MAGNETIC HEADING, PITCH, AND ROLL IN DEGREES\n");
    fprintf(output_file, "COMM, Then, after that, comes the values of each of the datarefs listed by the DREFS, in order!\n\n");
    fprintf(output_file, "COMM, So, you just list all the datarefs you like in the DREF labels, with some tabs or spaces and then a conversion factor for each, and then the data for those datarefs per-frame in the DATA labels after the time, location, and attitude!\n");
    fprintf(output_file, "COMM, What an easy format!\n");
    fprintf(output_file, "COMM, This lets you keep the files as short as you like... or add as much detail as you like as well!\n");
    fprintf(output_file, "COMM, Be sure to use COMMAS after each label!\n\n");
    fprintf(output_file, "ACFT, Aircraft/Laminar Research/Cessna 172 SP/Cessna_172SP.acf\n");  // DEMO
    fprintf(output_file, "TAIL, N12345\n");
    fprintf(output_file, "TIME, 12:00:00\n");   // Change According to the Times
    fprintf(output_file, "DATE, 05/1/2023\n");  // Change According to the Dates
    fprintf(output_file, "PRES, 29.92\n");
    fprintf(output_file, "DISA, 0\n");
    fprintf(output_file, "WIND, 180,10\n\n");

    fprintf(output_file, "WARN,10,Resources/sounds/alert/stall.WAV\n");
    fprintf(output_file, "WARN,20,Resources/sounds/alert/stall.WAV\n\n");

    fprintf(output_file, "DREF, sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot\t1.0\t\t// Baro Setting (in/HG)\n");
    fprintf(output_file, "DREF, sim/cockpit2/gauges/indicators/altitude_ft_pilot\t\t1.0\t\t// Altitude Baro\n");
    fprintf(output_file, "DREF, sim/cockpit2/gauges/indicators/vvi_fpm_pilot\t\t1.0\t\t// Vertical Speed (Feet/min)\n\n");

    fprintf(output_file, "DREF, sim/cockpit2/gauges/indicators/true_airspeed_kts_pilot\t\t1.0\t\t// True Air Speed (ktas)\n");
    fprintf(output_file, "DREF, sim/cockpit2/gauges/indicators/airspeed_kts_pilot\t\t1.0\t\t// Indicated Airspeed (knots)\n");
    fprintf(output_file, "DREF, sim/cockpit2/gauges/indicators/ground_speed_kt\t\t1.0\t\t// Ground Speed (gps-Knots)\n\n");

    fprintf(output_file, "DREF, sim/cockpit2/annunciators/stall_warning_ratio\t\t1.0\t\t// Stall Warning\n");
    fprintf(output_file, "DREF, sim/flightmodel2/controls/flap_handle_deploy_ratio\t0.5\t\t// Flaps (handle)\n");
    fprintf(output_file, "DREF, sim/cockpit2/controls/flap_ratio\t\t\t\t\t0.5\t\t// Flaps (surface)\tratio in X-Plane, steps in FDR file, so convert here.\n\n");

    fprintf(output_file, "DREF, sim/cockpit2/temperature/outside_air_temp_degc\t\t1.0\t\t// Outside Air Temp (deg C)\n");
    fprintf(output_file, "DREF, sim/cockpit2/gauges/indicators/wind_heading_deg_mag\t\t1.0\t\t// Wind Angle\n");
    fprintf(output_file, "DREF, sim/cockpit2/gauges/indicators/wind_speed_kts\t\t1.0\t\t// Wind Speed\n\n");

    fprintf(output_file, "DREF, sim/flightmodel/weight/m_fuel[0]\t\t2.662587\t// Fuel Qty Left (gal)\tkg in X-Plane. so this converts gallons to kilograms.\n");
    fprintf(output_file, "DREF, sim/flightmodel/weight/m_fuel[1]\t\t2.662587\t// Fuel Qty right (gal)\tkg in X-Plane. so this converts gallons to kilograms.\n\n");

    fprintf(output_file, "DREF, sim/cockpit2/electrical/bus_volts[0]\t\t1.0\t\t// volt\n");
    fprintf(output_file, "DREF, sim/cockpit2/electrical/battery_amps[0]\t\t1.0\t\t// amp\n");

    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/oil_pressure_psi[0]\t1.0\t// Oil Pressure (PSI)\n");
    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/oil_temperature_deg_C[0]\t1.0\t// Oil Temp (deg F)\n");
    fprintf(output_file, "DREF, sim/flightmodel/engine/ENGN_power[0]\t1491.40\t// Eng1 Percent Power watts in X-Plane. so this turns and entry of 100 into 149140 watts, or 200 hp.\n\n");

    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/prop_speed_rsc[0]\t0.10472\t// RPM rad/sec in X-Plane. so this converts RPM to radians per second\n");
    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/MPR_in_hg[0]\t1.0\t// Manifold Pressure (In/Hg)\n");
    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/fuel_flow_kg_sec[0]\t0.0007396\t// Fuel Flow (gal/hr) kg/sec in X-Plane. so this converts gallons per hour to kilograms per second.\n\n");

    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/CHT_CYL_deg_C[0]\t1.0\t// Cylinder Head Temp per cylinder, deg C (for multi-engine planes, start second engine at index 12, third engine at index 24 etc)\n");
    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/CHT_CYL_deg_C[1]\t1.0\t// Cylinder Head Temp per cylinder, deg C (for multi-engine planes, start second engine at index 12, third engine at index 24 etc)\n");
    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/CHT_CYL_deg_C[2]\t1.0\t// Cylinder Head Temp per cylinder, deg C (for multi-engine planes, start second engine at index 12, third engine at index 24 etc)\n");
    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/CHT_CYL_deg_C[3]\t1.0\t// Cylinder Head Temp per cylinder, deg C (for multi-engine planes, start second engine at index 12, third engine at index 24 etc)\n");
    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/CHT_CYL_deg_C[4]\t1.0\t// Cylinder Head Temp per cylinder, deg C (for multi-engine planes, start second engine at index 12, third engine at index 24 etc)\n");
    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/CHT_CYL_deg_C[5]\t1.0\t// Cylinder Head Temp per cylinder, deg C (for multi-engine planes, start second engine at index 12, third engine at index 24 etc)\n\n");

    fprintf(output_file, "DREF, sim/cockpit2/engine/indicators/EGT_CYL_deg_C[0]\t\t1.0\t\t// Exhaust Gas Temp per cylinder, deg C\n\n");
    
    // fprintf(output_file, "COMM,time,Longitude,Latitude,Altitude,HDG,Pitch,Roll,BaroA,AltMSL,VSpd,TAS,IAS,GndSpd,Stall Warning,flap,flap,OAT,wind,wind speed,FQtyL,FQtyR,volt1,amp1,OilP,OilT,Eng1 Percent Power,RPM,MAP,FFlow,CHT-1,CHT-2,CHT-3,CHT-4,CHT-5,CHT-6,EGT-1,EGT-2,EGT-3,EGT-4,EGT-5,EGT-6\n");
    fprintf(output_file, "COMM,time,Longitude,Latitude,Altitude,Pitch,Roll,Yaw\n");
    

    char line[256];
    while (fgets(line, sizeof(line), input_file)) {
        double data[9];
        char date[16];
        char time[16];
//-71.201749,42.002863,40.371,0.42,0.09,9.42,-0.04,0.04,0.03,,
        sscanf(line, "%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%s %s",
               &data[0], &data[1], &data[2], &data[3], &data[4], &data[5],
               &data[6], &data[7], &data[8], date, time);

        if (data[7] == 0) {
            count = count + 1;
        } else {
            // fprintf(output_file, "DATA,%d,%.6lf,%.6lf,200,0,%.2lf,%.2lf,30,5755.5,-12.9,148,131.9,137.4,0,0,0,15.2,357,12,19.2,19.3,27.9,0.4,44.4,186.7,82,2620.1,25,10.9,351.5,371.3,352.3,354.4,363.5,346.5,1381.8,1405.1,1382.2,1387.8,1408.6,1406.6\n",
            //     number, data[7], data[8], data[3], data[4]);
            fprintf(output_file, "DATA,%d,%lf,%lf,%lf,%lf,%lf,%lf\n",
                number, data[0], data[1], data[2], data[7], data[8], data[6]);
                number = number + 1;
        }
    }

    fclose(input_file);
    fclose(output_file);

    printf("Model of Airplane: Cessna 172 SP.\n");
    printf("Data parsed and written to output.fdr.\n");
    printf("The GPS clocked after %d cycles.\n", count);
    return 0;
}
