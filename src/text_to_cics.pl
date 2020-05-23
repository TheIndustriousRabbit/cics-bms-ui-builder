use v5;
use strict;

{
  package Main;

  sub add_to_queue {
    my $type = shift(@_);
    my $row = shift(@_);
    my $column = shift(@_);
    my $content = shift(@_);
    my $field_number = shift(@_);
    my $length = length($content);

    my $line;

    if ($type ne "text") {
      $line = substr("FIELD" . $field_number . "   ", 0, 7);
    } else {
      $line = "       ";
    }

    $line .=
      " DFHMDF POS=(" .
      $row .
      "," .
      $column .
      "), X\n" .
      "               LENGTH=" .
      $length .
      ", X\n".
      "               ATTRB=(ASKIP,NORM)";

    if ($type eq "text") {
      $line .= ", X\n               INITIAL='" . $content . "'";
    }

    return $line . "\n";
  }

  sub start {
    my $data = shift(@_);

    my @lines = split(/\n/, $data);
    my $out = "";

    my $row = 0;
    my $field_number = 0;
    for my $line (@lines) {
      my $current = undef;
      my $is_blank = false;
      my $start_column = undef;
      my $content = "";

      for (my $column = 0; $column < length($line); $column += 1) {
        my $char = substr($line, $column, 1);

        my $will_be = undef;

        if ($char eq "9") {
          $will_be = "numberfield";
        } elsif ($char eq "X") {
          $will_be = "textfield";
        } elsif ($char eq " ") {
          $will_be = "blank";
        } else {
          $will_be = "text";
        }

        if ($current eq $will_be) {
          $content .= $char;
        } else {
          if (defined($current) && $current ne "blank") {
            $out .= add_to_queue(
              $current,
              $row + 1,
              $start_column + 1,
              $content,
              $field_number
            );
            if ($current ne "text") {
              $field_number += 1;
            }
          }

          $current = $will_be;
          $start_column = $column;
          $content = $char;
        }
      }

      if ($current ne "blank") {
        $out .= add_to_queue(
          $current,
          $row + 1,
          $start_column + 1,
          $content,
          $field_number
        );
        if ($current ne "text") {
          $field_number += 1;
        }
      }

      $row += 1;
    }

    return $out;
  }
}
