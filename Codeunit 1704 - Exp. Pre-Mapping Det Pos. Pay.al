codeunit 50104 "PPExtPremapping"
{
    // version NAVW19.00
    TableNo = "Data Exch.";

    trigger OnRun();
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        LineNo: Integer;
    begin
        CheckLedgerEntry.SETRANGE("Data Exch. Entry No.", "Entry No.");
        PreparePosPayDetails(CheckLedgerEntry, "Entry No.", LineNo);

        // Reset filters and set it on the Data Exch. Voided Entry No.
        CheckLedgerEntry.RESET;
        CheckLedgerEntry.SETRANGE("Data Exch. Voided Entry No.", "Entry No.");
        PreparePosPayDetails(CheckLedgerEntry, "Entry No.", LineNo);
    end;

    var
        ProgressMsg: TextConst ENU = 'Preprocessing line no. #1######.', ESM = 'Preprocesando la línea n.º #1######.', FRC = 'Pré-traitement ligne n° #1######.', ENC = 'Preprocessing line no. #1######.';

    local procedure PreparePosPayDetails(var CheckLedgerEntry: Record "Check Ledger Entry"; DataExchangeEntryNo: Integer; var LineNo: Integer);
    var
        Window: Dialog;
    begin
        IF CheckLedgerEntry.FINDSET THEN BEGIN
            Window.OPEN(ProgressMsg);
            REPEAT
                LineNo += 1;
                Window.UPDATE(1, LineNo);
                PreparePosPayDetail(CheckLedgerEntry, DataExchangeEntryNo, LineNo);
            UNTIL CheckLedgerEntry.NEXT = 0;
            Window.CLOSE;
        END;
    end;

    local procedure PreparePosPayDetail(CheckLedgerEntry: Record "Check Ledger Entry"; DataExchangeEntryNo: Integer; LineNo: Integer);
    var
        BankAccount: Record "Bank Account";
        PosPayDetail: Record "Positive Pay Detail";
    begin
        BankAccount.GET(CheckLedgerEntry."Bank Account No.");

        WITH PosPayDetail DO BEGIN
            INIT;
            "Data Exch. Entry No." := DataExchangeEntryNo;
            "Entry No." := LineNo;
            "Account Number" := BankAccount."Bank Account No.";
            IF DataExchangeEntryNo = CheckLedgerEntry."Data Exch. Voided Entry No." THEN BEGIN
                // V for Void legend
                "Record Type Code" := 'V';
                "Void Check Indicator" := 'V';
                VoidStatusIndicator := '*26';
            END ELSE BEGIN
                // O for Open legend
                "Record Type Code" := 'O';
                "Void Check Indicator" := '';
                VoidStatusIndicator := '*10';
            END;
            "Check Number" := CheckLedgerEntry."Check No.";
            Amount := CheckLedgerEntry.Amount;
            Payee := CheckLedgerEntry.GetPayee;
            "Issue Date" := CheckLedgerEntry."Check Date";
            IF BankAccount."Currency Code" <> '' THEN
                "Currency Code" := BankAccount."Currency Code";

            INSERT(TRUE);
        END;
    end;
}

