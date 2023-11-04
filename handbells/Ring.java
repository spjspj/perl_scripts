package com.otique.handbell2020;

import java.io.*;
import java.util.*;

public class Ring 
{
    static String FIRST_STRING = "first";
    static String LAST_STRING = "last";


    // Calls
    static String PLAIN_STRING = "plain";
    static String BOB_STRING = "bob";
    static String SINGLE_STRING = "single";
    static class call
    {
        String the_call;
        public call (String conductor_call)
        {
            the_call = conductor_call;
        }

        public String get_the_call ()
        {
            return the_call;
        }

        void say_call ()
        {
            //System.out.println (get_the_call ());
        }

        public String toString ()
        {
            return get_the_call ();
        }
    }


    static class plain_call extends call
    {
        public plain_call () 
        {
            super (PLAIN_STRING);
        }

        public String get_the_call ()
        {
            return "";
        }

        void say_call ()
        {
            // Do nothing.. 
        }
    }

    static class single_call extends call
    {
        public single_call () 
        {
            super (SINGLE_STRING);
        }
    }

    
    static class bob_call extends call
    {
        public bob_call () 
        {
            super (BOB_STRING);
        }
    }

    static class rounds_call extends call
    {
        public rounds_call () 
        {
            super ("that's all");
        }
    }

    static class stand_call extends call
    {
        public stand_call () 
        {
            super ("stand");
        }
    }

    static class splice_call extends call
    {
        public splice_call (String method_name) 
        {
            super (method_name);
        }
    }

    static class go_call extends call
    {
        public go_call (String method_name) 
        {
            super ("go " + method_name);
        }
    }

    static class place_notation
    {
        // 000000, 110000, 111001  (for otique - 1 = stays in place..)
        // 'X', '1,2', '1,2,3'  (for otique - 1 = stays in place..)
        String place_notation_str;
        int number_bells;
        
        public place_notation (String str, int anumber_bells)
        {
            number_bells = anumber_bells;
            place_notation_str = str;
        }

        public String toString ()
        {
            return place_notation_str;
        }

        public void apply_to_change (change old_change)
        {
            if (place_notation_str.toUpperCase ().equals ("X"))
            {
                // Swap them all..
                if (number_bells % 2 != 0) 
                {
                    //System.out.println ("FFFFFFFFFFFFFAAAAAAAAAAAIIIIL\n");
                    return;
                }
                for (int x = 0; x < old_change.get_number_bells (); x += 2)
                {
                    int bell_in_first_pos = old_change.get_bell (x);
                    int bell_in_second_pos = old_change.get_bell (x+1);

                    old_change.set_bell (x, bell_in_second_pos );
                    old_change.set_bell (x+1, bell_in_first_pos );
                }
            }
            else
            {
                String aplace_notation_str = place_notation_str;
                aplace_notation_str = aplace_notation_str  + ",";
                String [] parts = aplace_notation_str.split (",");
                int [] stay_same_numbers = new int [parts.length];

                int idx = 0;
                for (String o : parts)
                {
                    int z = Integer.parseInt (o);
                    stay_same_numbers [idx] = z;
                    idx ++;
                }
                 
                // xxxxxxxxxxxxxxxxxxxxx
                int chg = 0;
                int x = 0;
                int bell_num = 1;
                //System.out.println ("x=0.." + old_change.get_number_bells ());
                //System.out.print (old_change.toString (-1) + " <<< old  ,," + old_change.get_number_bells () + ",,,  new >>>> ");

                while (x < old_change.get_number_bells ())
                {
                    if ((chg > stay_same_numbers.length - 1 && x <= old_change.get_number_bells () - 2) || (chg < stay_same_numbers.length && bell_num <= stay_same_numbers [chg] - 2))
                    {
                        // Swap them..
                        //System.out.print (" . swap " + x + " & " + (x+1) + " . ");
                        int bell_in_first_pos = old_change.get_bell (x);
                        int bell_in_second_pos = old_change.get_bell (x+1);
                        old_change.set_bell (x, bell_in_second_pos);
                        old_change.set_bell (x+1, bell_in_first_pos);
                        bell_num += 2;
                        x += 2;
                    }
                    else if (bell_num == old_change.get_number_bells ())
                    {
                        bell_num ++;
                        x++;
                    }
                    else if (bell_num == stay_same_numbers [chg])
                    {
                        chg++;
                        bell_num ++;
                        x++;
                    }
                    //System.out.println ("x=" + x);
                    //System.out.println ("=stay_same_numbers,,,chg" +  chg);
                }
                //System.out.println (old_change.toString (-1));

                /*for (int z = x; z < old_change.get_number_bells (); z++)
                {
                    int bell_in_pos = old_change.get_bell (z);
                    old_change.set_bell (z, bell_in_second_pos);
                }*/
            }
        }
    }

    static class touch
    {
        List <method> method_to_call = new ArrayList <method> ();
        List <call> call_list = new ArrayList <call> ();
        int call_index = 0;

        public touch (method amethod, List <call> acall_list)
        {
            add_course (amethod, acall_list);
            call_index = 0;
        }

        public void add_course (method amethod, List <call> acall_list)
        {
            if (call_list.size () != 0)
            {
                // Add in one of the calls to make a splice call
                splice_call spl = new splice_call (amethod.get_method_name ());
                //System.out.println ("Added in -- " + amethod.get_method_name ());
                //call_list.add (spl);
                //method_to_call.add (amethod);
            }

            for (call c : acall_list)
            {
                call_list.add (c);
                method_to_call.add (amethod);
            }
        }

        public List <String> ring_touch (change c, int number_rounds)
        {
            method_structure ms = method_to_call.get (call_index).get_method_structure ();
            int change_idx = 0;
            boolean can_finish = false;
            int must_finish = -1;
            
            List <String> str_changes = new ArrayList <String> ();
            
            for (int z = 0; z < (number_rounds-1)*2; z++)
            {
                str_changes.add ("c: " + c.toString (-1));
            }

            if (ms != null)
            {
                str_changes.add ("g:Go " + ms.method_name);
            }

            str_changes.add ("c: " + c.toString (-1));
            str_changes.add ("c: " + c.toString (-1));
            int num_leads = ms.get_number_changes_in_lead_end ();
            
            must_finish = (call_list.size () + c.get_number_bells () - 1) * num_leads;

            while (ms != null)
            {
                place_notation p = ms.get_current_place_notation ();

                while (p != null)
                {
                    change_idx ++;
                    boolean next_call_spliced = true;

                    // Check for potential spliced calls - can only call a splice at the start of a normal course..
                    if (method_to_call.size () > call_index+1)
                    {
                        method_structure next_ms = method_to_call.get (call_index + 1).get_method_structure ();
                        if (next_ms.method_name.equals (ms.method_name))
                        {
                            next_call_spliced = false;
                        }
                    }
                    else
                    {
                        next_call_spliced = false;
                    }

                    p.apply_to_change (c);
                    str_changes.add ("c: " + c.toString (-1));
                    p = ms.get_current_place_notation ();

                    if ((ms.is_current_place_notation_callable () && !next_call_spliced) 
                        || (ms.is_next_pn_first () && next_call_spliced))
                    {
                        if (ms.is_current_place_notation_callable () && !next_call_spliced) 
                        {
                            //System.out.println ("xxxxxx - normal - not next_call_spliced\n");
                        }
                        else if (ms.is_next_pn_first () && next_call_spliced)
                        {
                            method_structure next_ms = method_to_call.get (call_index + 1).get_method_structure ();
                            str_changes.add (change_idx + ".spl:" + next_ms.method_name);
                        }

                        if (method_to_call.size () > call_index)
                        {
                            ms.handle_call (call_list.get (call_index));
                            if (!(call_list.get (call_index).get_the_call ().equals ("")))
                            {
                                // Add one change earlier..
                                str_changes.add(str_changes.size() - 1, "ca:" + call_list.get (call_index).get_the_call ());
                            }
                            call_index++;
                            if (method_to_call.size () > call_index)
                            {
                                ms = method_to_call.get (call_index).get_method_structure ();
                            }
                            else
                            {
                                can_finish = true;
                            }
                        }
                    }
                    
                    if (must_finish > 0)
                    {
                        must_finish --;
                    }

                    if (c.is_rounds () || must_finish == 0)
                    {
                        str_changes.add ("ca:That's all!\n");
                        p = null;
                        ms = null;
                    }
                }
            }

            for (int z = 0; z < number_rounds*2; z++)
            {
                str_changes.add ("c: " + c.toString (-1));
            }

            str_changes.add ("ca:Stand");
            return str_changes;
        }
    }

    static class change
    {
        // declares an array of integers
        int [] bells;
        int number_bells;
        int number_of_change;
        boolean hand_stroke;

        // Rounds..
        public change (int anumber_bells)
        {
            if (anumber_bells < 0)
            {
                anumber_bells = 1;
            }

            number_bells = anumber_bells;

            bells = new int [number_bells];
            for (int x = 0; x < number_bells; x++)
            {
                bells [x] = x+1;
            }
        }

        public change (change old_change, place_notation a_place_notation, boolean is_hand_stroke, int number_change, int anumber_bells)
        {
            number_bells = anumber_bells;
            
            bells = new int [old_change.get_number_bells ()];

            for (int x = 0; x < old_change.get_number_bells (); x++)
            {
                bells [x] = old_change.get_bell (x);
            }

            number_of_change = number_change;
            hand_stroke = is_hand_stroke;
            // Apply the place_notation to this change..
            a_place_notation.apply_to_change (this);
        }
        
        public change (change change_to_copy)
        {
            bells = new int [change_to_copy.get_number_bells ()];
            for (int x = 0; x < change_to_copy.get_number_bells (); x++)
            {
                bells [x] = change_to_copy.get_bell (x);
            }
            number_of_change = change_to_copy.get_number_of_change ();
            hand_stroke = change_to_copy.get_hand_stroke ();
        }

        // constructor new_change (old_change, place_notation, is_hand_stroke, number_change)
        public String toString (int bell)
        {
            String c = "";
            for (int x = 0; x < get_number_bells (); x++)
            {
                if (bell == -1 || get_bell (x) == bell || get_bell (x) == 1)
                {
                    c += get_bell (x) + " ";
                }
                else
                {
                    c += ". ";
                }
            }
            return c;
        }

        public void set_bell (int bell_pos, int bell)
        {
            if (bell_pos >= number_bells) 
            {
                return;
            }
            bells [bell_pos] = bell;
        }

        public int get_bell (int i)
        {
            if (i < number_bells) 
            {
                return bells [i];
            }
            return -1;
        }

        public int get_number_bells ()
        {
            return number_bells;
        }

        public int get_number_of_change ()
        {
            return number_of_change;
        }

        public boolean get_hand_stroke ()
        {
            return hand_stroke;
        }

        public boolean is_rounds ()
        {
            for (int x = 0; x < get_number_bells (); x++)
            {
                if (get_bell (x) != x+1)
                {
                    return false;
                }
            }
            return true;
        }
    }

    static class method_structure
    {
        List <place_notation> pn_list = new ArrayList <place_notation> ();
        List <String> pn_names = new ArrayList <String> ();

        private List <String> goto_pn_names = new ArrayList <String> ();
        List <String> calls_for_pn = new ArrayList <String> ();
        List <Integer> num_poss_paths = new ArrayList <Integer> ();


        int pn_index;
        int number_bells;
        String goto_pn_name;
        String method_name;
        boolean is_first;
        private int next_pn_index = -1;

        public method_structure (int anum_bells, String amethod_name)
        {
            pn_index = 0;
            number_bells = anum_bells;
            method_name = amethod_name;
            is_first = true;
        }

        public void add_place_notation (place_notation apn)
        {
            //System.out.print ("Adding PN of -> " + apn.toString ());
            
            change c = new change (number_bells);
            apn.apply_to_change (c);
            //System.out.print (" ---  " + c.toString (-1));
            pn_list.add (apn);
            //System.out.println (" ---  Now there is " + pn_list.size () + " pns");
            pn_names.add ("");
            goto_pn_names.add ("");
            calls_for_pn.add ("");
            num_poss_paths.add (1);
        }

        public void add_info_for_last_pn (call acall, String goto_apn_name, String name)
        {
            if (acall != null)
            {
                int val = num_poss_paths.get (num_poss_paths.size () - 1);
                val ++;
                num_poss_paths.set (num_poss_paths.size () - 1, val);
                calls_for_pn.set (calls_for_pn.size () - 1, calls_for_pn.get (calls_for_pn.size () - 1)  + acall + ",");
                goto_pn_names.set (goto_pn_names.size () - 1, goto_pn_names.get (goto_pn_names.size () - 1)  + goto_apn_name + ",");
            }

            if (acall == null && goto_apn_name != null)
            {
                goto_pn_names.set (goto_pn_names.size () - 1, goto_pn_names.get (goto_pn_names.size () - 1)  + goto_apn_name + ",");
            }

            if (name != null)
            {
                pn_names.set (pn_names.size () - 1, name);
            }
        }

        public void add_info_for_named_pn (call acall, String goto_apn_name, String name_pn)
        {
            int idx = index_of_pn_by_name (name_pn);

            if (idx != -1)
            {
                int val = num_poss_paths.get (idx);
                val ++;
                num_poss_paths.set (idx, val);
                calls_for_pn.set (idx, calls_for_pn.get (idx)  + acall + ",");
                goto_pn_names.set (idx, goto_pn_names.get (idx)  + goto_apn_name + ",");
            }
        }

        public int index_of_pn_by_name (String aname)
        {
            if (aname != null)
            {
                int idx = 0;
                for (String name : pn_names)
                {
                    if (name.equalsIgnoreCase (aname))
                    {
                        return idx;
                    }
                    idx++;
                }
            }
            return -1;
        }
         
        public place_notation find_pn_by_name (String aname)
        {
            if (aname != null)
            {
                int idx = 0;
                for (String name : pn_names)
                {
                    if (name.equalsIgnoreCase (aname))
                    {
                        return pn_list.get (idx);
                    }
                    idx++;
                }
            }
            return null;
        }

        private int get_current_pn_index () 
        {
            String g = goto_pn_names.get (pn_index);
            String c = calls_for_pn.get (pn_index).toString ();
            if (c.equals ("") && !g.equals (""))
            {
                //System.out.println ("   goto = " + g);
                String [] gs = g.split (",");
                next_pn_index = index_of_pn_by_name (gs [0]);
                return pn_index;
            }
            return pn_index;
        }

        public boolean is_current_place_notation_callable () 
        {
            if (num_poss_paths.size () > pn_index)
            {
                //int xxx = get_current_pn_index ();
                //System.out.println ("   xxx = " + xxx);
                return num_poss_paths.get (get_current_pn_index ()) > 1;
            }
            return false;
        }

        public void handle_call (call acall) 
        {
            if (is_current_place_notation_callable ()) 
            {
                String g = goto_pn_names.get (get_current_pn_index ());
                String c = calls_for_pn.get (get_current_pn_index ()).toString ();
                next_pn_index = -1;
                //System.out.println (acall.toString () + " .... " + g + ",,,," + c);
                String [] cs = c.split (",");
                String [] gs = g.split (",");

                int xx = 0;
                for (String c2 : cs)
                {
                    //System.out.println ("    >>> if (" + c2 + ") == (" + acall.toString () + ")");
                    if (c2.equalsIgnoreCase (acall.toString ()))
                    {
                        //System.out.println ("    >>> yaaaa (" + gs[xx]);
                        next_pn_index = index_of_pn_by_name (gs [xx]);
                    }
                    xx ++;
                }
            }
        }

        public void reset ()
        {
            pn_index = 0;
            is_first = true;
        }

        public place_notation get_current_place_notation ()
        {
            if (is_first)
            {
                pn_index = index_of_pn_by_name (FIRST_STRING);
                is_first = false;
                return pn_list.get (pn_index);
            }


            if (pn_list.size () > pn_index)
            {
                pn_index ++;
                if (next_pn_index != -1) 
                {
                    pn_index = next_pn_index;
                    //System.out.println (pn_list.size () + " Calling !!!!!!! based on a call!!! " + pn_index);
                }
                next_pn_index = -1;
                return pn_list.get (get_current_pn_index ());
            }
            else
            {
                //System.out.println (pn_list.size () + " SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS" + pn_index);
                pn_index = 1;
                return pn_list.get (get_current_pn_index ());
            }
        }

        public String get_current_place_notation_name ()
        {
            int cc = get_current_pn_index ();
            if (cc >= 0)
            {
                return pn_names.get (cc);
            }
            return "";
        }
        
        public boolean is_current_place_notation_first ()
        {
            String current = get_current_place_notation_name ();
            return (current.startsWith (FIRST_STRING));
        }

        // Is the next call going to be back to the first pn of the course??
        public boolean is_next_pn_first ()
        {
            int curr = get_current_pn_index (); 
            if (curr >= 0)
            {
                String g = goto_pn_names.get (get_current_pn_index ());
                return g.startsWith (FIRST_STRING);
            }
            
            return false;
        }

        public String toString ()
        {
            String x = "";
            if (pn_list != null)
            {
                x = "method: " + method_name + "   -- #Place notations: " + pn_list.size () + "\n";
                int i = 0;

                for (place_notation p : pn_list)
                {
                    String n = pn_names.get (i);
                    String g = goto_pn_names.get (i);
                    String c = calls_for_pn.get (i).toString ();
                    int n2 = num_poss_paths.get (i);
                    x += i + ": " + p.toString () + "\n";
                    x += "   Info =    name=" + n + ",   goto=" + g + ",    calls=" + c + ",       num_poss=" + n2 + "\n";
                    i++;
                }
            }
            return x;
        }

        public int get_number_changes_in_lead_end ()
        {
            // Go from the first to where there is a 'goto' and then back to first..
            int num_leads = 0;
            int next_pn_index = 0;
            if (pn_list != null)
            {
                while (!(num_leads > 0 && next_pn_index == 0))
                {
                    num_leads ++;
                    String n = pn_names.get (next_pn_index);
                    String g = goto_pn_names.get (next_pn_index);

                    if (!(g.equals ("")))
                    {
                        String [] gs = g.split (",");
                        next_pn_index = index_of_pn_by_name (gs [0]);
                    }
                    else
                    {
                        next_pn_index++;
                    }
                }
            }
            return num_leads;
        }
    }

    static class method
    {
        private String name = "";
        private int number_bells = -1;
        method_structure ms = null;
        List <call> calls_from_file = new ArrayList <call> ();

        public method (String afile_name)
        {
            BufferedReader br;
            int line_num = 0;

            try 
            {
                br = new BufferedReader (new FileReader (afile_name));
                StringBuilder sb = new StringBuilder();
                String line = br.readLine();

                while (line != null) 
                {
                    //0) 5
                    //1) Grandsire Doubles
                    //2) Repeat
                    //3) 3.1.5.1.5.1.5.
                    //4) Until Rounds
                    //5) Principle
                    //6) PlainLead
                    //7) 1.5.1.
                    //8) BobLead
                    //9) 1.3.1.
                    //A) SingleLead
                    //b) 1.3.1,2,3.
                    //c) Method
                    //d) -,S,P,S,-,S,P,S,-,S,P,S.

                    if (line_num == 0)
                    {
                        // Number of bells..
                        number_bells = Integer.parseInt (line);
                        //System.out.println (" #### bels Seen: " + number_bells);
                    }
                    if (line_num == 1)
                    {
                        // Method name
                        name = line;
                        //System.out.println (" #### name Seen: " + name);
                        ms = new method_structure (number_bells, name);
                    }
                    if (line_num == 3)
                    {
                        // The place notation..
                        String [] parts = line.split ("\\.");
                        int i;
                        for (i = 0; i < parts.length; i++)
                        {
                            //System.out.println (" #### place not Seen: " + line + ",,," + i + "....." + parts.length);
                            place_notation p  = new place_notation (parts [i], number_bells);
                            ms.add_place_notation (p);
                            if (i == 0)
                            {
                                ms.add_info_for_last_pn (null, null, FIRST_STRING);
                            }
                            if (i == parts.length - 1)
                            {
                                ms.add_info_for_last_pn (null, null, LAST_STRING);
                            }
                        }
                    }
                    if (line_num == 7)
                    {
                        // The place notation..
                        String [] parts = line.split ("\\.");
                        int i;
                        for (i = 0; i < parts.length; i++)
                        {
                            //System.out.println (" #### place not Seen: " + line + ",,," + i + "....." + parts.length);
                            place_notation p  = new place_notation (parts [i], number_bells);
                            ms.add_place_notation (p);
                            ms.add_info_for_last_pn (null, null, PLAIN_STRING + i);

                            if (i == 0)
                            {
                                // Plain..
                                call plain = new plain_call ();
                                ms.add_info_for_named_pn (plain, PLAIN_STRING + i, LAST_STRING);
                            }
                            if (i == parts.length - 1)
                            {
                                ms.add_info_for_last_pn (null, FIRST_STRING, null);
                            }
                        }
                    }
                    if (line_num == 9)
                    {
                        // The place notation..
                        String [] parts = line.split ("\\.");
                        int i;
                        for (i = 0; i < parts.length; i++)
                        {
                            //System.out.println (" #### place not Seen: " + line + ",,," + i + "....." + parts.length);
                            place_notation p  = new place_notation (parts [i], number_bells);
                            ms.add_place_notation (p);
                            ms.add_info_for_last_pn (null, null, BOB_STRING + i);

                            if (i == 0)
                            {
                                // Bob..
                                call bob = new call (BOB_STRING);
                                ms.add_info_for_named_pn (bob, BOB_STRING + i, LAST_STRING);
                            }
                            if (i == parts.length - 1)
                            {
                                ms.add_info_for_last_pn (null, FIRST_STRING, null);
                            }
                        }
                    }
                    if (line_num == 11)
                    {
                        // The place notation..
                        String [] parts = line.split ("\\.");
                        int i;
                        for (i = 0; i < parts.length; i++)
                        {
                            //System.out.println (" #### place not Seen: " + line + ",,," + i + "....." + parts.length);
                            place_notation p  = new place_notation (parts [i], number_bells);
                            ms.add_place_notation (p);
                            ms.add_info_for_last_pn (null, null, SINGLE_STRING + i);

                            if (i == 0)
                            {
                                // Single..
                                call single = new call (SINGLE_STRING);
                                ms.add_info_for_named_pn (single, SINGLE_STRING + i, LAST_STRING);
                            }
                            if (i == parts.length - 1)
                            {
                                ms.add_info_for_last_pn (null, FIRST_STRING, null);
                            }
                        }
                    }
                    if (line_num == 13)
                    {
                        // An actual proper touch..
                        //d) -,S,P,S,-,S,P,S,-,S,P,S.
                        String [] parts = line.split ("\\,");
                        call acall;
                        int i;
                        for (i = 0; i < parts.length; i++)
                        {
                            boolean ok_to_add = false;
                            if (parts [i].startsWith ("S"))
                            {
                                acall = new single_call ();
                                calls_from_file.add (acall);
        
                            }
                            else if (parts [i].startsWith ("-"))
                            {
                                acall = new bob_call ();
                                calls_from_file.add (acall);
                            }
                            else if (parts [i].startsWith ("P"))
                            {
                                acall = new plain_call ();
                                calls_from_file.add (acall);
                            }
                        }
                    }

                    //System.out.println ("Line: " + line);
                    sb.append (line);
                    sb.append ("\n");
                    line = br.readLine ();
                    line_num ++;
                }
                //System.out.println ("Method Structure:\n" + ms.toString ());
                //System.exit (0);
                br.close();
            }
            catch (Exception e) 
            {
                e.printStackTrace ();
                //System.out.println ("Exception: " + e);
            }
        }

        public method_structure get_method_structure ()
        {
            return ms;
        }

        public int get_number_bells ()
        {
            return number_bells;
        }

        public String get_method_name ()
        {
            return name;
        }
    }

    public List <String> otique_touch () 
    {
        //System.out.println ("Welcome to the java ringer");
        //System.out.println ("This will be used to simulate ringing for an eventual android app..");
        method m = new method ("/mnt/sdcard/download/GrandsireDoubles.bell");
        List <call> calls = new ArrayList <call> ();
        call acall;
        acall = new bob_call ();         calls.add (acall);
        acall = new single_call ();         calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new single_call ();         calls.add (acall);
        acall = new bob_call ();         calls.add (acall);
        acall = new single_call ();         calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new single_call ();         calls.add (acall);
        acall = new bob_call ();         calls.add (acall);
        acall = new single_call ();         calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new single_call ();         calls.add (acall);
        touch t = new touch (m, calls);
        t.add_course (m, calls);
        //List <String> all_things = t.ring_touch (c, 5);
        //for (String s : all_things)
        //{
         //   //System.out.println (s);
        //}
        //System.out.println ("------------------------------------");
        //System.out.println ("------------------------------------");
        //System.out.println ("------------------------------------");
        //System.out.println ("------------------------------------");
        //System.out.println ("------------------------------------");
        //System.out.println ("------------------------------------");
        method m2 = new method ("/mnt/sdcard/download/CambridgeSurpriseMinor.bell");
        change c = new change (m2.get_number_bells ());
//
        List <call> calls2 = new ArrayList <call> ();
        acall = new plain_call ();
        calls2.add (acall);
        calls2.add (acall);
        calls2.add (acall);
        calls2.add (acall);
        calls2.add (acall);
        touch t2 = new touch (m2, calls2);
        t2.add_course (m, calls);
        //System.out.println ("------------------------------------");
        //System.out.println (t2.toString ());
        //System.out.println ("------------------------------------");
        t2.add_course (m, calls);

        List <String> all_things = t2.ring_touch (c, 5);
        for (String s : all_things)
        {
            //System.out.println (s);
        }
        //System.out.println ("TOTAL MEM = " + Runtime.getRuntime ().totalMemory ());
        //System.out.println ("TOTAL FREE MEM = " + Runtime.getRuntime ().freeMemory ());
        //System.out.println ("TOTAL minused MEM = " + (Runtime.getRuntime ().totalMemory () - Runtime.getRuntime ().freeMemory ()));
        
        return all_things;
    }
    
    public List <String> plain_touch (String file_name) 
    {
        //System.out.println ("Welcome to the java ringer");
        //System.out.println ("This will be used to simulate ringing for an eventual android app..");
        method m = new method (file_name);
        List <call> calls = new ArrayList <call> ();
        call acall;
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        touch t = new touch (m, calls);
        t.add_course (m, calls);
        change c = new change (m.get_number_bells ());

        List <String> all_things = t.ring_touch (c, 5);
        //System.out.println ("TOTAL MEM = " + Runtime.getRuntime ().totalMemory ());
        //System.out.println ("TOTAL FREE MEM = " + Runtime.getRuntime ().freeMemory ());
        //System.out.println ("TOTAL minused MEM = " + (Runtime.getRuntime ().totalMemory () - Runtime.getRuntime ().freeMemory ()));
        return all_things;
    }

    public List <String> bob_from_file (String file_name) 
    {
        method m = new method (file_name);
        List <call> calls = new ArrayList <call> ();
        call acall;
        acall = new bob_call (); calls.add (acall);
        acall = new bob_call (); calls.add (acall);
        acall = new bob_call (); calls.add (acall);
        acall = new bob_call (); calls.add (acall);
        acall = new bob_call (); calls.add (acall);
        acall = new bob_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new bob_call (); calls.add (acall);
        acall = new bob_call (); calls.add (acall);
        acall = new bob_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        
        touch t = new touch (m, calls);
        t.add_course (m, calls);
        change c = new change (m.get_number_bells ());

        List <String> all_things = t.ring_touch (c, 5);
        return all_things;
    }

    public List <String> single_from_file (String file_name)
    {
        method m = new method (file_name);
        List <call> calls = new ArrayList <call> ();
        call acall;
        acall = new single_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new plain_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        acall = new single_call (); calls.add (acall);
        touch t = new touch (m, calls);
        t.add_course (m, calls);
        change c = new change (m.get_number_bells ());

        List <String> all_things = t.ring_touch (c, 5);
        return all_things;
    }

    public List <String> touch_from_file (String file_name)
    {
        method m = new method (file_name);
        List <call> calls = m.calls_from_file;

        touch t = new touch (m, calls);
        change c = new change (m.get_number_bells ());

        List <String> all_things = t.ring_touch (c, 5);
        return all_things;
    }
}
